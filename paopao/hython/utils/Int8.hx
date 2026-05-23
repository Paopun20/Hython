package paopao.hython.utils;

#if cpp
typedef Int8 = cpp.Int8;
#elseif cs
typedef Int8 = cs.Int8;
#elseif java
typedef Int8 = java.Int8;
#else
import Std;

@:transitive
@:analyzer(optimize, local_dce, fusion, user_var_fusion)
@:nullSafety(Strict) abstract Int8(Int) from Int to Int {
	static inline var MAX:Int = 127;
	static inline var MIN:Int = -128;
	static inline var MASK:Int = 0xFF;

	public function new(v:Int) {
		this = wrap(v);
	}

	// Wrap to signed 8-bit range [-128, 127]
	static inline function wrap(v:Int):Int {
		var masked = v & MASK;
		return (masked >= 128) ? masked - 256 : masked;
	}

	// Arithmetic operators (with overflow wrapping)
	@:op(A + B) public inline function add(b:Int8):Int8
		return new Int8(this + (b : Int));

	@:op(A - B) public inline function sub(b:Int8):Int8
		return new Int8(this - (b : Int));

	@:op(A * B) public inline function mul(b:Int8):Int8
		return new Int8(this * (b : Int));

	@:op(A / B) public inline function div(b:Int8):Int8
		return new Int8(Std.int(this / (b : Int)));

	@:op(A % B) public inline function mod(b:Int8):Int8
		return new Int8(this % (b : Int));

	// Unary
	@:op(-A) public inline function negate():Int8
		return new Int8(-this);

	// Bitwise operators
	@:op(A & B) public inline function and(b:Int8):Int8
		return new Int8(this & (b : Int));

	@:op(A | B) public inline function or(b:Int8):Int8
		return new Int8(this | (b : Int));

	@:op(A ^ B) public inline function xor(b:Int8):Int8
		return new Int8(this ^ (b : Int));

	@:op(~A) public inline function not():Int8
		return new Int8(~this);

	@:op(A << B) public inline function shl(b:Int):Int8
		return new Int8(this << b);

	@:op(A >> B) public inline function shr(b:Int):Int8
		return new Int8(this >> b);

	// Comparison
	@:op(A == B) public inline function eq(b:Int8):Bool
		return this == (b : Int);

	@:op(A != B) public inline function neq(b:Int8):Bool
		return this != (b : Int);

	@:op(A < B) public inline function lt(b:Int8):Bool
		return this < (b : Int);

	@:op(A <= B) public inline function lte(b:Int8):Bool
		return this <= (b : Int);

	@:op(A > B) public inline function gt(b:Int8):Bool
		return this > (b : Int);

	@:op(A >= B) public inline function gte(b:Int8):Bool
		return this >= (b : Int);

	// Utilities
	public inline function toUInt8():Int
		return this & MASK; // unsigned view [0, 255]

	public inline function isNegative():Bool
		return this < 0;

	public inline function abs():Int8
		return this < 0 ? new Int8(-this) : new Int8(this);

	public inline function clamp(lo:Int8, hi:Int8):Int8 {
		if (this < (lo : Int))
			return lo;
		if (this > (hi : Int))
			return hi;
		return new Int8(this);
	}

	public inline function toString():String
		return Std.string(this);

	@:from public static inline function fromInt(v:Int):Int8
		return new Int8(v);

	@:to public inline function toInt():Int
		return this;
}
#end
