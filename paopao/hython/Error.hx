package paopao.hython;

enum Error {
	EInvalidChar(c:Int);
	EUnexpected(s:String);
	EUnterminatedString;
	EUnterminatedComment;
	EInvalidPreprocessor(msg:String);
	EUnknownVariable(v:String);
	EInvalidIterator(v:String);
	EInvalidOp(op:String);
	EInvalidAccess(f:String);
	ECustom(msg:String);
	ETypeError(msg:String);
	EValueError(msg:String);
	ETabError(msg:String);
	EZeroDivisionError(msg:String);
	EExitException(code:Int);
	ERecursionError(msg:String);
	EAssertionError(msg:String);
	ENameError(msg:String);
	EKeyError(msg:String);
	EAttributeError(msg:String);
	EClassNotAllowed(msg:String);
	ESyntaxError(msg:String);
}