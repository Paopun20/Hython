package paopao.hython.bytecode;
import paopao.hython.Ast;
import haxe.io.BytesOutput;
import haxe.io.Bytes;
import haxe.ds.StringMap;

// Opcodes - raw byte values
class Opcode {
	public static inline var LOAD_CONST = 0x00;
	public static inline var LOAD_LOCAL = 0x01;
	public static inline var LOAD_GLOBAL = 0x02;
	public static inline var LOAD_ARG = 0x03;
	public static inline var STORE_LOCAL = 0x04;
	public static inline var STORE_GLOBAL = 0x05;
	public static inline var STORE_ARG = 0x06;
	public static inline var STORE_FIELD = 0x07;
	public static inline var STORE_INDEX = 0x08;
	public static inline var STORE_TUPLE = 0x09;
	public static inline var LOAD_FIELD = 0x0A;
	public static inline var LOAD_INDEX = 0x0B;
	public static inline var BINOP = 0x0C;
	public static inline var UNOP = 0x0D;
	public static inline var JUMP = 0x0E;
	public static inline var JUMP_IF_FALSE = 0x0F;
	public static inline var CALL = 0x10;
	public static inline var RETURN = 0x11;
	public static inline var BUILD_DICT = 0x12;
	public static inline var DICT_SET = 0x13;
	public static inline var MAKE_FUNCTION = 0x14;
	public static inline var ADD_ASSIGN = 0x15;
	public static inline var SUB_ASSIGN = 0x16;
	public static inline var MUL_ASSIGN = 0x17;
	public static inline var DIV_ASSIGN = 0x18;
	public static inline var ADD_ASSIGN_GLOBAL = 0x19;
	public static inline var SUB_ASSIGN_GLOBAL = 0x1A;
	public static inline var MUL_ASSIGN_GLOBAL = 0x1B;
	public static inline var DIV_ASSIGN_GLOBAL = 0x1C;
	public static inline var MODIFY_ARG = 0x1D;
	public static inline var IMPORT = 0x1E;
	public static inline var IMPORT_FROM = 0x1F;
	public static inline var SWITCH = 0x20;
}

// Constant type tags
class ConstantType {
	public static inline var NULL = 0x00;
	public static inline var INT = 0x01;
	public static inline var FLOAT = 0x02;
	public static inline var STRING = 0x03;
	public static inline var BOOL = 0x04;
}

class BytecodeCompiler {
	private var instructionsBuffer:BytesOutput;
	private var constants:Array<Dynamic> = [];
	private var constantMap:StringMap<Int> = new StringMap<Int>();
	private var jumpPatches:Array<{offset:Int, target:Int}> = [];

	public function new() {
		instructionsBuffer = new BytesOutput();
	}

	public function compile(ast:Expr):Bytes {
		instructionsBuffer = new BytesOutput();
		constants = [];
		constantMap = new StringMap<Int>();
		jumpPatches = [];

		compileExpr(ast);
		emit(Opcode.RETURN);

		// Apply jump patches
		var instructionBytes = instructionsBuffer.getBytes();
		for (patch in jumpPatches) {
			// Patch the 4-byte jump target at offset + 1 (skip opcode)
			instructionBytes.setInt32(patch.offset, patch.target);
		}

		// Build final bytecode structure
		var output = new BytesOutput();
		
		// Magic number: "HYB\0"
		output.writeByte(0x48); // 'H'
		output.writeByte(0x59); // 'Y'
		output.writeByte(0x42); // 'B'
		output.writeByte(0x00);
		
		// Version: 1
		output.writeByte(0x01);
		
		// Constants count
		output.writeInt32(constants.length);
		
		// Write all constants
		for (c in constants) {
			if (c == null) {
				output.writeByte(ConstantType.NULL);
			} else if (Std.isOfType(c, Bool)) {
				output.writeByte(ConstantType.BOOL);
				output.writeByte(cast(c, Bool) ? 1 : 0);
			} else if (Std.isOfType(c, Int)) {
				output.writeByte(ConstantType.INT);
				output.writeInt32(cast(c, Int));
			} else if (Std.isOfType(c, Float)) {
				output.writeByte(ConstantType.FLOAT);
				output.writeDouble(cast(c, Float));
			} else if (Std.isOfType(c, String)) {
				output.writeByte(ConstantType.STRING);
				writeString(output, cast(c, String));
			}
		}
		
		// Instructions count
		output.writeInt32(instructionBytes.length);
		
		// Write all instructions
		output.write(instructionBytes);
		
		return output.getBytes();
	}

	private function compileExpr(expr:Expr):Void {
		switch expr.expr {
			case EConstInt(n):
				emitConstant(n);
			case EConstFloat(f):
				emitConstant(f);
			case EConstString(s):
				emitConstant(s);
			case EConstBool(b):
				emitConstant(b);
			case EConstNone:
				emitConstant(null);

			case EVar(v):
				switch v {
					case VLocal(id):
						emit(Opcode.LOAD_LOCAL);
						writeInt32(id);
					case VGlobal(id):
						emit(Opcode.LOAD_GLOBAL);
						writeInt32(id);
					case VArg(id):
						emit(Opcode.LOAD_ARG);
						writeInt32(id);
				}

			case EAssign(target, op, value):
				compileExpr(value);
				compileAssignTarget(target, op);

			case EBinop(op, left, right):
				compileExpr(left);
				compileExpr(right);
				var opCode = compileBinop(op);
				emit(Opcode.BINOP);
				instructionsBuffer.writeByte(opCode);

			case EUnop(op, operand):
				compileExpr(operand);
				var opCode = compileUnop(op);
				emit(Opcode.UNOP);
				instructionsBuffer.writeByte(opCode);

			case EIf(cond, thenExpr, elseExpr):
				compileExpr(cond);
				var jumpIfFalseIdx = instructionsBuffer.length;
				emit(Opcode.JUMP_IF_FALSE);
				writeInt32(0); // placeholder

				compileExpr(thenExpr);
				var jumpIdx = instructionsBuffer.length;
				emit(Opcode.JUMP);
				writeInt32(0); // placeholder

				// patch JUMP_IF_FALSE
				patchJump(jumpIfFalseIdx + 1, instructionsBuffer.length);

				compileExpr(elseExpr);

				// patch JUMP
				patchJump(jumpIdx + 1, instructionsBuffer.length);

			case EWhile(cond, body):
				var loopStartIdx = instructionsBuffer.length;
				compileExpr(cond);
				var jumpIfFalseIdx = instructionsBuffer.length;
				emit(Opcode.JUMP_IF_FALSE);
				writeInt32(0); // placeholder

				compileExpr(body);
				emit(Opcode.JUMP);
				writeInt32(loopStartIdx);

				// patch JUMP_IF_FALSE
				patchJump(jumpIfFalseIdx + 1, instructionsBuffer.length);

			case EBlock(exprs):
				for (e in exprs) {
					compileExpr(e);
				}

			case EFunction(args, body):
				var funcId = addConstant(null); // placeholder for function object
				emit(Opcode.MAKE_FUNCTION);
				instructionsBuffer.writeByte(args.length);
				writeInt32(funcId);

			case ECall(func, args):
				compileExpr(func);
				for (a in args) {
					compileExpr(a);
				}
				emit(Opcode.CALL);
				instructionsBuffer.writeByte(args.length);

			case EReturn(e):
				compileExpr(e);
				emit(Opcode.RETURN);

			case EField(obj, name):
				compileExpr(obj);
				emit(Opcode.LOAD_FIELD);
				writeString(instructionsBuffer, name);

			case EIndex(obj, index):
				compileExpr(obj);
				compileExpr(index);
				emit(Opcode.LOAD_INDEX);

			case EObject(fields):
				emit(Opcode.BUILD_DICT);
				instructionsBuffer.writeByte(fields.length);
				for (f in fields) {
					var nameId = addConstant(f.name);
					emit(Opcode.LOAD_CONST);
					writeInt32(nameId);
					compileExpr(f.expr);
					emit(Opcode.DICT_SET);
				}

			case EImport(_, _):
				emit(Opcode.IMPORT);

			case EImportFrom(_, _):
				emit(Opcode.IMPORT_FROM);

			case ESwitch(_, _, _):
				emit(Opcode.SWITCH);

			case EInfo(_):
				// Skip info nodes
		};
	}

	private function compileAssignTarget(target:AssignTarget, op:AssignOp):Void {
		switch target {
			case TVar(v):
				switch v {
					case VLocal(id):
						switch op {
							case Assign:
								emit(Opcode.STORE_LOCAL);
								writeInt32(id);
							case AddAssign:
								emit(Opcode.ADD_ASSIGN);
								writeInt32(id);
							case SubAssign:
								emit(Opcode.SUB_ASSIGN);
								writeInt32(id);
							case MulAssign:
								emit(Opcode.MUL_ASSIGN);
								writeInt32(id);
							case DivAssign:
								emit(Opcode.DIV_ASSIGN);
								writeInt32(id);
						}
					case VGlobal(id):
						switch op {
							case Assign:
								emit(Opcode.STORE_GLOBAL);
								writeInt32(id);
							case AddAssign:
								emit(Opcode.ADD_ASSIGN_GLOBAL);
								writeInt32(id);
							case SubAssign:
								emit(Opcode.SUB_ASSIGN_GLOBAL);
								writeInt32(id);
							case MulAssign:
								emit(Opcode.MUL_ASSIGN_GLOBAL);
								writeInt32(id);
							case DivAssign:
								emit(Opcode.DIV_ASSIGN_GLOBAL);
								writeInt32(id);
						}
					case VArg(id):
						switch op {
							case Assign:
								emit(Opcode.STORE_ARG);
								writeInt32(id);
							default:
								emit(Opcode.MODIFY_ARG);
								writeInt32(id);
						}
				}

			case TField(obj, name):
				compileExpr(obj);
				emit(Opcode.STORE_FIELD);
				writeString(instructionsBuffer, name);

			case TIndex(obj, index):
				compileExpr(obj);
				compileExpr(index);
				emit(Opcode.STORE_INDEX);

			case TTuple(_):
				emit(Opcode.STORE_TUPLE);
		};
	}

	private function compileBinop(op:ExprBinop):Int {
		return switch op {
			case ADD: 0x00;
			case SUB: 0x01;
			case MUL: 0x02;
			case DIV: 0x03;
			case MOD: 0x04;
			case EQ: 0x05;
			case NEQ: 0x06;
			case LT: 0x07;
			case GT: 0x08;
			case LTE: 0x09;
			case GTE: 0x0A;
			case AND: 0x0B;
			case OR: 0x0C;
		};
	}

	private function compileUnop(op:ExprUnop):Int {
		return switch op {
			case NEG: 0x00;
			case NOT: 0x01;
			case NEG_BIT: 0x02;
			case INC: 0x03;
			case DEC: 0x04;
		};
	}

	private function emitConstant(value:Dynamic):Void {
		var id = addConstant(value);
		emit(Opcode.LOAD_CONST);
		writeInt32(id);
	}

	private function addConstant(value:Dynamic):Int {
		var key = "";
		if (value == null) {
			key = "null";
		} else if (Std.isOfType(value, Bool)) {
			key = "b:" + value;
		} else if (Std.isOfType(value, Int)) {
			key = "i:" + value;
		} else if (Std.isOfType(value, Float)) {
			key = "f:" + value;
		} else if (Std.isOfType(value, String)) {
			key = "s:" + cast(value, String);
		}

		if (constantMap.exists(key)) {
			return constantMap.get(key);
		}

		var id = constants.length;
		constants.push(value);
		constantMap.set(key, id);
		return id;
	}

	private function emit(opcode:Int):Void {
		instructionsBuffer.writeByte((opcode : Int));
	}

	private function writeInt32(value:Int):Void {
		instructionsBuffer.writeInt32(value);
	}

	private function writeString(buf:BytesOutput, s:String):Void {
		var bytes = Bytes.ofString(s);
		buf.writeInt32(bytes.length);
		buf.write(bytes);
	}

	private function patchJump(offset:Int, target:Int):Void {
		jumpPatches.push({offset: offset, target: target});
	}
}
