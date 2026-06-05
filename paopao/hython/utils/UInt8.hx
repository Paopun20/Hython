package paopao.hython.utils;

#if cpp
typedef UInt8 = cpp.UInt8;
#elseif cs
typedef UInt8 = cs.UInt8;
#else
import Std;

@:transitive
@:analyzer(optimize, local_dce, fusion, user_var_fusion)
@:nullSafety(Strict) abstract UInt8(Int) from Int to Int {
	static inline var MAX:Int = 256;
	static inline var MIN:Int = 0;
	static inline var MASK:Int = 0xFF;

	public function new(v:Int) {
		this = wrap(v);
	}

	// Wrap to unsigned 8-bit range [0, 255]
	static inline function wrap(v:Int):Int {
		return v & MASK; // always [0, 255]
	}

	// Arithmetic operators (with overflow wrapping)
	@:op(A + B) public inline function add(b:UInt8):UInt8
		return new UInt8(this + (b : Int));

	@:op(A - B) public inline function sub(b:UInt8):UInt8
		return new UInt8(this - (b : Int));

	@:op(A * B) public inline function mul(b:UInt8):UInt8
		return new UInt8(this * (b : Int));

	@:op(A / B) public inline function div(b:UInt8):UInt8
		return new UInt8(Std.int(this / (b : Int)));

	@:op(A % B) public inline function mod(b:UInt8):UInt8
		return new UInt8(this % (b : Int));

	// Unary
	@:op(-A) public inline function negate():UInt8
		return new UInt8(-this);

	// Bitwise operators
	@:op(A & B) public inline function and(b:UInt8):UInt8
		return new UInt8(this & (b : Int));

	@:op(A | B) public inline function or(b:UInt8):UInt8
		return new UInt8(this | (b : Int));

	@:op(A ^ B) public inline function xor(b:UInt8):UInt8
		return new UInt8(this ^ (b : Int));

	@:op(~A) public inline function not():UInt8
		return new UInt8(~this);

	@:op(A << B) public inline function shl(b:Int):UInt8
		return new UInt8(this << b);

	@:op(A >> B) public inline function shr(b:Int):UInt8
		return new UInt8(this >> b);

	// Comparison
	@:op(A == B) public inline function eq(b:UInt8):Bool
		return this == (b : Int);

	@:op(A != B) public inline function neq(b:UInt8):Bool
		return this != (b : Int);

	@:op(A < B) public inline function lt(b:UInt8):Bool
		return this < (b : Int);

	@:op(A <= B) public inline function lte(b:UInt8):Bool
		return this <= (b : Int);

	@:op(A > B) public inline function gt(b:UInt8):Bool
		return this > (b : Int);

	@:op(A >= B) public inline function gte(b:UInt8):Bool
		return this >= (b : Int);

	// Utilities
	public inline function toUInt8():Int
		return this & MASK; // unsigned view [0, 255]

	public inline function isNegative():Bool
		return this < 0;

	public inline function abs():UInt8
		return this < 0 ? new UInt8(-this) : new UInt8(this);

	public inline function clamp(lo:UInt8, hi:UInt8):UInt8 {
		if (this < (lo : Int))
			return lo;
		if (this > (hi : Int))
			return hi;
		return new UInt8(this);
	}

	public inline function toString():String
		return Std.string(this);

	@:from public static inline function fromInt(v:Int):UInt8
		return new UInt8(v);

	@:to public inline function toInt():Int
		return this;
}
#end
