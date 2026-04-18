package paopao.hython.bytecode;
import paopao.hython.Ast;
import haxe.io.BytesInput;
import haxe.io.Bytes;

class BytecodeDeserializer {
	private var input:BytesInput;
	private var constants:Array<Dynamic> = [];

	public function new() {}

	public function deserialize(bytes:Bytes):Expr {
		input = new BytesInput(bytes);

		// Read and verify magic number
		var magic = input.readByte(); // 'H'
		var magic2 = input.readByte(); // 'Y'
		var magic3 = input.readByte(); // 'B'
		var magic4 = input.readByte(); // '\0'

		if (magic != 0x48 || magic2 != 0x59 || magic3 != 0x42 || magic4 != 0x00) {
			throw "Invalid bytecode magic number";
		}

		// Read version
		var version = input.readByte();
		if (version != 0x01) {
			throw "Unsupported bytecode version: " + version;
		}

		// Read constants
		var constantCount = input.readInt32();
		constants = [];
		for (i in 0...constantCount) {
			var constantType = input.readByte();
			var constant:Dynamic = null;

			switch (constantType) {
				case 0x00: // NULL
					constant = null;
				case 0x04: // BOOL
					constant = input.readByte() != 0;
				case 0x01: // INT
					constant = input.readInt32();
				case 0x02: // FLOAT
					constant = input.readDouble();
				case 0x03: // STRING
					var strLen = input.readInt32();
					constant = input.readString(strLen);
				default:
					throw "Unknown constant type: " + constantType;
			}

			constants.push(constant);
		}

		// Read instructions
		var instructionCount = input.readInt32();
		var instructions:Array<Int> = [];
		for (i in 0...instructionCount) {
			instructions.push(input.readByte());
		}

		// Deserialize instructions to expression
		var pc = 0;
		return deserializeInstructions(instructions, pc);
	}

	private function deserializeInstructions(instructions:Array<Int>, startPc:Int):Expr {
		var pc = startPc;
		var stack:Array<Expr> = [];

		while (pc < instructions.length) {
			var opcode = instructions[pc];
			pc++;

			switch (opcode) {
				case 0x00: // LOAD_CONST
					var constId = readInt32(instructions, pc);
					pc += 4;
					var value = constants[constId];
					stack.push(createConstExpr(value));

				case 0x01: // LOAD_LOCAL
					var id = readInt32(instructions, pc);
					pc += 4;
					stack.push(new Expr(EVar(VLocal(id)), 0, 0));

				case 0x02: // LOAD_GLOBAL
					var id = readInt32(instructions, pc);
					pc += 4;
					stack.push(new Expr(EVar(VGlobal(id)), 0, 0));

				case 0x03: // LOAD_ARG
					var id = readInt32(instructions, pc);
					pc += 4;
					stack.push(new Expr(EVar(VArg(id)), 0, 0));

				case 0x04: // STORE_LOCAL
					var id = readInt32(instructions, pc);
					pc += 4;
					var value = stack.pop();
					stack.push(new Expr(EAssign(TVar(VLocal(id)), Assign, value), 0, 0));

				case 0x05: // STORE_GLOBAL
					var id = readInt32(instructions, pc);
					pc += 4;
					var value = stack.pop();
					stack.push(new Expr(EAssign(TVar(VGlobal(id)), Assign, value), 0, 0));

				case 0x06: // STORE_ARG
					var id = readInt32(instructions, pc);
					pc += 4;
					var value = stack.pop();
					stack.push(new Expr(EAssign(TVar(VArg(id)), Assign, value), 0, 0));

				case 0x0C: // BINOP
					var opType = instructions[pc];
					pc++;
					var right = stack.pop();
					var left = stack.pop();
					var binOp = compileBinopReverse(opType);
					stack.push(new Expr(EBinop(binOp, left, right), 0, 0));

				case 0x0D: // UNOP
					var opType = instructions[pc];
					pc++;
					var operand = stack.pop();
					var unOp = compileUnopReverse(opType);
					stack.push(new Expr(EUnop(unOp, operand), 0, 0));

				case 0x0E: // JUMP
					var target = readInt32(instructions, pc);
					pc = target;

				case 0x0F: // JUMP_IF_FALSE
					var target = readInt32(instructions, pc);
					pc += 4;
					var cond = stack.pop();
					// Note: Jump targets need proper reconstruction context
					stack.push(cond);

				case 0x10: // CALL
					var argCount = instructions[pc];
					pc++;
					var args:Array<Expr> = [];
					for (i in 0...argCount) {
						args.unshift(stack.pop());
					}
					var func = stack.pop();
					stack.push(new Expr(ECall(func, args), 0, 0));

				case 0x11: // RETURN
					if (stack.length > 0) {
						return stack[stack.length - 1];
					}
					return new Expr(EConstNone, 0, 0);

				case 0x0A: // LOAD_FIELD
					var strLen = readInt32(instructions, pc);
					pc += 4;
					var fieldName = input.readString(strLen);
					var obj = stack.pop();
					stack.push(new Expr(EField(obj, fieldName), 0, 0));

				case 0x0B: // LOAD_INDEX
					var index = stack.pop();
					var obj = stack.pop();
					stack.push(new Expr(EIndex(obj, index), 0, 0));

				case 0x12: // BUILD_DICT
					var fieldCount = instructions[pc];
					pc++;
					var fields:Array<ObjectField> = [];
					for (i in 0...fieldCount) {
						var value = stack.pop();
						var nameId = stack.pop();
						var name = "";
						// Extract name from constant if available
						switch (nameId.expr) {
							case EConstString(n):
								name = n;
							default:
								name = "";
						}
						fields.unshift(new ObjectField(name, value));
					}
					stack.push(new Expr(EObject(fields), 0, 0));

				case 0x14: // MAKE_FUNCTION
					var argCount = instructions[pc];
					pc++;
					var funcId = readInt32(instructions, pc);
					pc += 4;
					// For now, we'll create a placeholder EFunction
					// The actual function body would need to be reconstructed from bytecode
					// This is a simplified implementation
					var args:Array<Argument> = [];
					for (i in 0...argCount) {
						args.push(new Argument(VLocal(i), false, null));
					}
					// Create a dummy body for now
					stack.push(new Expr(EFunction(args, new Expr(EConstNone, 0, 0)), 0, 0));

				default:
					throw "Unknown opcode: " + opcode;
			}
		}

		if (stack.length > 0) {
			return stack[0];
		}

		return new Expr(EConstNone, 0, 0);
	}

	private function createConstExpr(value:Dynamic):Expr {
		if (value == null) {
			return new Expr(EConstNone, 0, 0);
		} else if (Std.isOfType(value, Bool)) {
			return new Expr(EConstBool(cast(value, Bool)), 0, 0);
		} else if (Std.isOfType(value, Int)) {
			return new Expr(EConstInt(cast(value, Int)), 0, 0);
		} else if (Std.isOfType(value, Float)) {
			return new Expr(EConstFloat(cast(value, Float)), 0, 0);
		} else if (Std.isOfType(value, String)) {
			return new Expr(EConstString(cast(value, String)), 0, 0);
		}
		return new Expr(EConstNone, 0, 0);
	}

	private function compileBinopReverse(opCode:Int):ExprBinop {
		return switch (opCode) {
			case 0x00: ExprBinop.ADD;
			case 0x01: ExprBinop.SUB;
			case 0x02: ExprBinop.MUL;
			case 0x03: ExprBinop.DIV;
			case 0x04: ExprBinop.MOD;
			case 0x05: ExprBinop.EQ;
			case 0x06: ExprBinop.NEQ;
			case 0x07: ExprBinop.LT;
			case 0x08: ExprBinop.GT;
			case 0x09: ExprBinop.LTE;
			case 0x0A: ExprBinop.GTE;
			case 0x0B: ExprBinop.AND;
			case 0x0C: ExprBinop.OR;
			default: ExprBinop.ADD;
		};
	}

	private function compileUnopReverse(opCode:Int):ExprUnop {
		return switch (opCode) {
			case 0x00: ExprUnop.NEG;
			case 0x01: ExprUnop.NOT;
			case 0x02: ExprUnop.NEG_BIT;
			case 0x03: ExprUnop.INC;
			case 0x04: ExprUnop.DEC;
			default: ExprUnop.NEG;
		};
	}

	private function readInt32(instructions:Array<Int>, offset:Int):Int {
		var b0 = instructions[offset];
		var b1 = instructions[offset + 1];
		var b2 = instructions[offset + 2];
		var b3 = instructions[offset + 3];
		return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
	}
}
