// This file implements the Bytecode Compiler for Hython.
// It performs a single-pass tree-walk over the AST (Module → Stmt → Expr)
// and emits OpCode instructions into a CodeObject.
//
// Design notes
// -------------
//  • Stack-based, CPython-inspired instruction set (see Bytecode.hx).
//  • Jump targets are first emitted as logical label IDs (LABEL pseudo-ops).
//    After each CodeObject is fully built, resolveLabels() strips every LABEL
//    node and rewrites all jump operands to absolute instruction indices.
//  • Nested functions / lambdas / class bodies each get their own CodeObject,
//    which is embedded into the parent via MAKE_FUNCTION.
//  • A loopStack tracks (startLabel, afterLabel) for each active loop so that
//    `break` and `continue` can emit the correct targets.
//  • The compiler does NOT perform optimisation; that is left to a future pass.
package paopao.hython;

import paopao.hython.Ast;
import paopao.hython.Bytecode;
import paopao.hython.Error;

private typedef LoopContext = {
	startLabel:Int, // target for `continue`
	afterLabel:Int // target for `break`
}
@:analyzer(optimize, local_dce, fusion, user_var_fusion)
class Compiler {
	// Monotonically-increasing label counter (global across all CodeObjects
	// so that label IDs are unique even in nested code objects).
	private var labelCounter:Int = 0;

	// Stack of active loop contexts — pushed on SETUP_LOOP, popped on POP_BLOCK.
	private var loopStack:Array<LoopContext> = [];

	public function new() {}

	// Compile a full module into a top-level CodeObject.
	public function compile(module:Module):CodeObject {
		var code = new CodeObject("<module>", []);

		compileBlock(module.body, code);

		// Modules implicitly return None.
		emit(code, LOAD_CONST(CNone));
		emit(code, RETURN_VALUE);

		resolveLabels(code);
		return code;
	}

	// Allocate a fresh label ID.
	private function newLabel():Int {
		return labelCounter++;
	}

	// Append an opcode to a CodeObject's instruction list.
	private inline function emit(code:CodeObject, op:OpCode):Void {
		code.instructions.push(op);
	}

	// Insert a LABEL pseudo-instruction as a jump target anchor.
	private inline function emitLabel(code:CodeObject, id:Int):Void {
		code.instructions.push(LABEL(id));
	}

	// Strip LABEL pseudo-instructions and rewrite every jump operand
	// from a logical label ID to an absolute instruction index.
	// Must be called once after each CodeObject is fully emitted.
	private function resolveLabels(code:CodeObject):Void {
		// ① Build label-id → flat-index map (LABELs don't count as real ops).
		var labelMap = new Map<Int, Int>();
		var idx = 0;
		for (op in code.instructions) {
			switch (op) {
				case LABEL(id):
					labelMap.set(id, idx);
				default:
					idx++;
			}
		}

		// ② Rewrite jumps; drop LABEL nodes.
		var resolved:Array<OpCode> = [];
		for (op in code.instructions) {
			switch (op) {
				case LABEL(_): // stripped

				case FOR_ITER(l): resolved.push(FOR_ITER(labelMap[l]));
				case JUMP_ABSOLUTE(l): resolved.push(JUMP_ABSOLUTE(labelMap[l]));
				case JUMP_FORWARD(l): resolved.push(JUMP_FORWARD(labelMap[l]));
				case POP_JUMP_IF_FALSE(l): resolved.push(POP_JUMP_IF_FALSE(labelMap[l]));
				case POP_JUMP_IF_TRUE(l): resolved.push(POP_JUMP_IF_TRUE(labelMap[l]));
				case SETUP_LOOP(l): resolved.push(SETUP_LOOP(labelMap[l]));
				case CONTINUE_LOOP(l): resolved.push(CONTINUE_LOOP(labelMap[l]));
				case SETUP_EXCEPT(l): resolved.push(SETUP_EXCEPT(labelMap[l]));
				case SETUP_FINALLY(l): resolved.push(SETUP_FINALLY(labelMap[l]));

				default: resolved.push(op);
			}
		}
		code.instructions = resolved;
	}

	private function compileBlock(stmts:Array<Stmt>, code:CodeObject):Void {
		for (stmt in stmts)
			compileStmt(stmt, code);
	}

	private function compileStmt(stmt:Stmt, code:CodeObject):Void {
		switch (stmt) {

			// pass → NOP
			case SPass:
				emit(code, NOP);

			// Standalone expression — value is discarded.
			case SExpr(expr):
				compileExpr(expr, code);
				emit(code, POP_TOP);

			// a = b = value
			// Compile value once; for each extra target duplicate first.
			case SAssign(targets, value):
				compileExpr(value, code);
				var n = targets.length;
				for (i in 0...n) {
					// All targets except the last need a copy of the value.
					if (i < n - 1) emit(code, DUP_TOP);
					compileAssignTarget(targets[i], code);
				}

			// return [expr]
			case SReturn(value):
				if (value != null)
					compileExpr(value, code);
				else
					emit(code, LOAD_CONST(CNone));
				emit(code, RETURN_VALUE);

			// if test: body [else: orelse]
			//
			//   <test>
			//   POP_JUMP_IF_FALSE  →elseLabel
			//   <body>
			//   JUMP_FORWARD       →endLabel
			// elseLabel:
			//   <orelse>
			// endLabel:
			case SIf(test, body, orelse):
				var elseLabel = newLabel();
				var endLabel = newLabel();

				compileExpr(test, code);
				emit(code, POP_JUMP_IF_FALSE(elseLabel));
				compileBlock(body, code);
				emit(code, JUMP_FORWARD(endLabel));
				emitLabel(code, elseLabel);
				compileBlock(orelse, code);
				emitLabel(code, endLabel);

			// while test: body [else: orelse]
			//
			//   SETUP_LOOP         →afterLabel
			// loopStart:
			//   <test>
			//   POP_JUMP_IF_FALSE  →loopEnd
			//   <body>
			//   JUMP_ABSOLUTE      →loopStart
			// loopEnd:
			//   POP_BLOCK
			//   <orelse>
			// afterLabel:
			case SWhile(test, body, orelse):
				var loopStart = newLabel();
				var loopEnd = newLabel();
				var afterLabel = newLabel();

				emit(code, SETUP_LOOP(afterLabel));
				loopStack.push({startLabel: loopStart, afterLabel: loopEnd});

				emitLabel(code, loopStart);
				compileExpr(test, code);
				emit(code, POP_JUMP_IF_FALSE(loopEnd));
				compileBlock(body, code);
				emit(code, JUMP_ABSOLUTE(loopStart));

				emitLabel(code, loopEnd);
				emit(code, POP_BLOCK);
				loopStack.pop();
				compileBlock(orelse, code);
				emitLabel(code, afterLabel);

			// for target in iter: body [else: orelse]
			//
			//   SETUP_LOOP         →afterLabel
			//   <iter>
			//   GET_ITER
			// loopStart:
			//   FOR_ITER           →loopEnd
			//   <store target>
			//   <body>
			//   JUMP_ABSOLUTE      →loopStart
			// loopEnd:
			//   POP_BLOCK
			//   <orelse>
			// afterLabel:
			case SFor(target, iter, body, orelse, _):
				var loopStart = newLabel();
				var loopEnd = newLabel();
				var afterLabel = newLabel();

				emit(code, SETUP_LOOP(afterLabel));
				compileExpr(iter, code);
				emit(code, GET_ITER);
				loopStack.push({startLabel: loopStart, afterLabel: loopEnd});

				emitLabel(code, loopStart);
				emit(code, FOR_ITER(loopEnd));
				compileAssignTarget(target, code);
				compileBlock(body, code);
				emit(code, JUMP_ABSOLUTE(loopStart));

				emitLabel(code, loopEnd);
				emit(code, POP_BLOCK);
				loopStack.pop();
				compileBlock(orelse, code);
				emitLabel(code, afterLabel);

			// break — exits the innermost loop.
			case SBreak:
				emit(code, BREAK_LOOP);

			// continue — restarts the innermost loop.
			case SContinue:
				if (loopStack.length == 0)
					throw new Error(SyntaxError("continue outside loop"), 0, 0);
				var ctx = loopStack[loopStack.length - 1];
				emit(code, CONTINUE_LOOP(ctx.startLabel));

			// def [async] name(args) -> ret: body
			// The body is compiled into a child CodeObject; a MAKE_FUNCTION
			// instruction pushes a callable wrapping it; STORE_NAME binds it.
			case SFunctionDef(name, args, body, _, isAsync):
				var funcCode = compileFunctionBody(name, args, body, isAsync);
				emit(code, MAKE_FUNCTION(funcCode));
				emit(code, STORE_NAME(name));

			// class name(bases): body
			//
			//   LOAD_CONST  name_str
			//   <base0> … <baseN>
			//   MAKE_FUNCTION  <class_body_code>
			//   CALL_FUNCTION  0    ; execute class body → dict
			//   BUILD_CLASS    N    ; (name, *bases, dict) → class obj
			//   STORE_NAME  name
			case SClassDef(name, bases, body):
				emit(code, LOAD_CONST(CString(name)));
				for (b in bases) compileExpr(b, code);

				var classCode = new CodeObject(name, []);
				compileBlock(body, classCode);
				classCode.instructions.push(LOAD_CONST(CNone));
				classCode.instructions.push(RETURN_VALUE);
				resolveLabels(classCode);

				emit(code, MAKE_FUNCTION(classCode));
				emit(code, CALL_FUNCTION(0));
				emit(code, BUILD_CLASS(bases.length));
				emit(code, STORE_NAME(name));

			// try: body [except H: …] [else: …] [finally: …]
			case STry(body, handlers, orelse, finalbody):
				compileTry(body, handlers, orelse, finalbody, code);

			// import a [as x], b [as y]
			case SImport(names):
				for (alias in names) {
					emit(code, IMPORT_NAME(alias.name));
					var localName = alias.asname != null ? alias.asname : alias.name;
					emit(code, STORE_NAME(localName));
				}

			// from module import a [as x], b [as y]
			case SImportFrom(module, names):
				emit(code, IMPORT_NAME(module));
				for (alias in names) {
					emit(code, IMPORT_FROM(alias.name));
					var localName = alias.asname != null ? alias.asname : alias.name;
					emit(code, STORE_NAME(localName));
				}
				// Discard the module object now that all attributes are extracted.
				emit(code, POP_TOP);
		}
	}

	// try / except / else / finally

	// Emits the full exception-handling block structure.
	//
	// Layout (with both handlers and finally):
	//
	//   SETUP_FINALLY  →finallyLabel
	//   SETUP_EXCEPT   →handlerLabel
	//   <try body>
	//   POP_BLOCK                    ; normal exit of except block
	//   <else body>
	//   JUMP_FORWARD   →finallyLabel ; jump over handlers to finally
	// handlerLabel:
	//   for each handler:
	//     [DUP_TOP / type check / POP_JUMP_IF_FALSE →nextHandler]
	//     POP_TOP × 3               ; discard exc_type, exc_value, traceback
	//     [STORE_NAME name]
	//     <handler body>
	//     JUMP_FORWARD →endLabel
	//   nextHandler:
	//   END_FINALLY                  ; re-raise if no handler matched
	// finallyLabel:
	//   <finally body>
	//   END_FINALLY
	// endLabel:
	private function compileTry(body:Array<Stmt>, handlers:Array<ExceptHandler>, orelse:Array<Stmt>, finalbody:Array<Stmt>,
			code:CodeObject):Void {
		var handlerLabel = newLabel();
		var finallyLabel = newLabel();
		var endLabel = newLabel();

		var hasHandlers = handlers.length > 0;
		var hasFinally = finalbody.length > 0;

		if (hasFinally) emit(code, SETUP_FINALLY(finallyLabel));
		if (hasHandlers) emit(code, SETUP_EXCEPT(handlerLabel));

		// try body
		compileBlock(body, code);
		if (hasHandlers) emit(code, POP_BLOCK);
		compileBlock(orelse, code);
		emit(code, JUMP_FORWARD(hasFinally ? finallyLabel : endLabel));

		// exception handlers
		if (hasHandlers) {
			emitLabel(code, handlerLabel);
			for (h in handlers) {
				var nextHandlerLabel = newLabel();

				if (h.type != null) {
					// Stack at handler entry: [exc_type, exc_value, traceback]
					// Check whether exc_value matches h.type.
					emit(code, DUP_TOP); // duplicate exc_type for comparison
					compileExpr(h.type, code);
					// In a full VM this would be COMPARE_EXCEPTION; we use a
					// simplified jump here and rely on the VM for type checking.
					emit(code, POP_JUMP_IF_FALSE(nextHandlerLabel));
				}

				// Matched — consume the three exception stack entries.
				emit(code, POP_TOP); // exc_type
				emit(code, POP_TOP); // exc_value
				emit(code, POP_TOP); // traceback

				if (h.name != null) emit(code, STORE_NAME(h.name));

				compileBlock(h.body, code);
				emit(code, JUMP_FORWARD(endLabel));

				emitLabel(code, nextHandlerLabel);
			}
			// No handler matched — propagate the exception.
			emit(code, END_FINALLY);
		}

		// finally block
		if (hasFinally) {
			emitLabel(code, finallyLabel);
			compileBlock(finalbody, code);
			emit(code, END_FINALLY);
		}

		emitLabel(code, endLabel);
	}

	// Function Body

	// Compile a function (or async function) body into a child CodeObject.
	private function compileFunctionBody(name:String, args:Arguments, body:Array<Stmt>, isAsync:Bool):CodeObject {
		var argNames = [for (a in args.args) a.name];

		// Detect generators: any YIELD_VALUE anywhere in the raw body
		// (we check the AST rather than post-emission for simplicity).
		var isGen = bodyContainsYield(body);

		var funcCode = new CodeObject(name, argNames, isAsync, isGen);
		compileBlock(body, funcCode);

		// Implicit `return None` at the end of every function.
		funcCode.instructions.push(LOAD_CONST(CNone));
		funcCode.instructions.push(RETURN_VALUE);

		resolveLabels(funcCode);
		return funcCode;
	}

	// Shallow AST scan: true if any SExpr(EYield(_)) appears in `stmts`.
	private function bodyContainsYield(stmts:Array<Stmt>):Bool {
		for (stmt in stmts) {
			switch (stmt) {
				case SExpr(EYield(_)): return true;
				case SIf(_, body, orelse): if (bodyContainsYield(body) || bodyContainsYield(orelse)) return true;
				case SWhile(_, body, _): if (bodyContainsYield(body)) return true;
				case SFor(_, _, body, orelse, _): if (bodyContainsYield(body) || bodyContainsYield(orelse)) return true;
				case STry(body, _, orelse, fin): if (bodyContainsYield(body) || bodyContainsYield(orelse) || bodyContainsYield(fin)) return true;
				default:
			}
		}
		return false;
	}

	// Expression Compilation

	private function compileExpr(expr:Expr, code:CodeObject):Void {
		switch (expr) {

			// Literal constant → push it directly.
			case EConstant(value):
				emit(code, LOAD_CONST(value));

			// Variable read.
			case EName(name):
				emit(code, LOAD_NAME(name));

			// left OP right
			case EBinOp(left, op, right):
				// Short-circuit evaluation for `and` / `or`.
				switch (op) {
					case And:
						compileShortCircuitAnd(left, right, code);
					case Or:
						compileShortCircuitOr(left, right, code);
					default:
						compileExpr(left, code);
						compileExpr(right, code);
						emit(code, BINARY_OP(op));
				}

			// OP operand
			case EUnaryOp(op, operand):
				compileExpr(operand, code);
				emit(code, UNARY_OP(op));

			// func(arg0, arg1, …)
			case ECall(func, args):
				compileExpr(func, code);
				for (a in args) compileExpr(a, code);
				emit(code, CALL_FUNCTION(args.length));

			// obj.attr
			case EAttribute(value, attr):
				compileExpr(value, code);
				emit(code, LOAD_ATTR(attr));

			// obj[index]
			case ESubscript(value, slice):
				compileExpr(value, code);
				compileExpr(slice, code);
				emit(code, BINARY_SUBSCR);

			// [e0, e1, …]
			case EList(elts):
				for (e in elts) compileExpr(e, code);
				emit(code, BUILD_LIST(elts.length));

			// (e0, e1, …)
			case ETuple(elts):
				for (e in elts) compileExpr(e, code);
				emit(code, BUILD_TUPLE(elts.length));

			// {k0: v0, k1: v1, …}
			case EDict(keys, values):
				var n = keys.length;
				for (i in 0...n) {
					compileExpr(keys[i], code);
					compileExpr(values[i], code);
				}
				emit(code, BUILD_DICT(n));

			// body if test else orelse
			//
			//   <test>
			//   POP_JUMP_IF_FALSE  →elseLabel
			//   <body>
			//   JUMP_FORWARD       →endLabel
			// elseLabel:
			//   <orelse>
			// endLabel:
			case EIfExp(test, body, orelse):
				var elseLabel = newLabel();
				var endLabel = newLabel();
				compileExpr(test, code);
				emit(code, POP_JUMP_IF_FALSE(elseLabel));
				compileExpr(body, code);
				emit(code, JUMP_FORWARD(endLabel));
				emitLabel(code, elseLabel);
				compileExpr(orelse, code);
				emitLabel(code, endLabel);

			// lambda args: expr
			// Compiles the body expression into a child CodeObject.
			case ELambda(args, body):
				var argNames = [for (a in args.args) a.name];
				var lambdaCode = new CodeObject("<lambda>", argNames);
				compileExpr(body, lambdaCode);
				lambdaCode.instructions.push(RETURN_VALUE);
				resolveLabels(lambdaCode);
				emit(code, MAKE_FUNCTION(lambdaCode));

			// await expr
			case EAwait(value):
				compileExpr(value, code);
				emit(code, GET_AWAITABLE);

			// yield [expr]
			case EYield(value):
				if (value != null)
					compileExpr(value, code);
				else
					emit(code, LOAD_CONST(CNone));
				emit(code, YIELD_VALUE);
		}
	}

	// Short-circuit `and`: evaluate right only if left is truthy.
	//
	//   <left>
	//   DUP_TOP
	//   POP_JUMP_IF_FALSE  →end    ; left is falsy — keep left on stack
	//   POP_TOP                    ; discard left (it was truthy)
	//   <right>
	// end:
	private function compileShortCircuitAnd(left:Expr, right:Expr, code:CodeObject):Void {
		var endLabel = newLabel();
		compileExpr(left, code);
		emit(code, DUP_TOP);
		emit(code, POP_JUMP_IF_FALSE(endLabel));
		emit(code, POP_TOP);
		compileExpr(right, code);
		emitLabel(code, endLabel);
	}

	// Short-circuit `or`: evaluate right only if left is falsy.
	//
	//   <left>
	//   DUP_TOP
	//   POP_JUMP_IF_TRUE   →end    ; left is truthy — keep left on stack
	//   POP_TOP                    ; discard left (it was falsy)
	//   <right>
	// end:
	private function compileShortCircuitOr(left:Expr, right:Expr, code:CodeObject):Void {
		var endLabel = newLabel();
		compileExpr(left, code);
		emit(code, DUP_TOP);
		emit(code, POP_JUMP_IF_TRUE(endLabel));
		emit(code, POP_TOP);
		compileExpr(right, code);
		emitLabel(code, endLabel);
	}

	// Assignment Targets

	// Emit instructions that store TOS into the given assignment target.
	// For tuple/list unpacking, UNPACK_SEQUENCE splits TOS into N values.
	private function compileAssignTarget(expr:Expr, code:CodeObject):Void {
		switch (expr) {

			case EName(name):
				emit(code, STORE_NAME(name));

			// (a, b, c) = … or [a, b, c] = …
			case ETuple(elts) | EList(elts):
				emit(code, UNPACK_SEQUENCE(elts.length));
				for (e in elts) compileAssignTarget(e, code);

			// obj.attr = …  →  need obj on stack below the value.
			// At this point TOS is the value to store; we compile `obj`
			// which pushes the object, then ROT_TWO to get value on top.
			case EAttribute(value, attr):
				compileExpr(value, code);
				emit(code, ROT_TWO);
				emit(code, STORE_ATTR(attr));

			// obj[idx] = …  →  need obj and idx on stack below the value.
			// Stack before STORE_SUBSCR: [value, obj, idx]  (TOS = idx)
			case ESubscript(value, slice):
				compileExpr(value, code);
				compileExpr(slice, code);
				// Stack now: [value_to_store, obj, idx]  (TOS = idx)
				emit(code, STORE_SUBSCR);

			default:
				throw new Error(SyntaxError("invalid assignment target"), 0, 0);
		}
	}
}
