namespace BeefParser
{
	public enum TokenType
	{
		// Keywords
		Void,
	    Object,
	    Bool,

		Char,
		Byte,
		SByte,
		Short,
		UShort,
	    Int, 
	    UInt,
		Long,
		ULong,
		Float,
	    Double,
		Decimal,
	    String,
	    True,
	    False,
		Null,

		Is,
		As,
		Append,
		Scope,
		New,
		Delete,
		TypeOf,
		SizeOf,
		DeclType,
		CompType,

		//Global,
		//Var,

		Public,
		Internal,
		Protected,
		Private,
		Static,
		
		Namespace,
		Class,
		Struct,
		Interface,
		Enum,
		Extension,
		
		Abstract,
		Const,
		Extern,
		Override,
		Partial,
		ReadOnly,
		Sealed,
		Unsafe,
		Virtual,
		Volatile,
		Mixin,
		Mut,

		Get,
		Set,

		Defer,
		Using,
		TypeAlias,
		Lock,
		Where,
		Try,
		Catch,
		Finally,
		If,
		Else, 
		Do,
		Repeat,
		For,
		Foreach,
		While,
		Switch,
		Default,
		Case,
		When,
		In,
		Out,
		Ref,
		Var,
		Let,

		Goto,
		Throw,
		Return,
		Break,
		Continue,
		Yield,

		Implicit,
		Explicit,
		Operator,
		Delegate,
		Function,
		Event,

		// Literals
	    IntegerLiteral,
	    FloatLiteral,	 
	    DoubleLiteral,
	    StringLiteral,
	    CharLiteral,

		// Interpolation
		InterpolatedStringStart,
		InterpolatedStringEnd,
		InterpolatedStringText,
		InterpolationStart,
		InterpolationEnd,

		Identifier,

		// Operators
	    Not, 		// !
	    HashTag,  	// #
	    Plus, 		// +
	    Minus, 		// -
	    Mul, 		// *
	    Div, 		// /
	    Module, 	// %

		NotEqual, 	// !=
		Equal, 		// ==
		StrictEqual,// ===
		//Greater, 	// >
		GreaterEq, 	// >=
		//Lesser, 	// <
		LesserEq, 	// <=
		Spaceship,	// <=>

		// Misc
		Colon, 		// :
		DoubleColon,// ::
		Comma, 		// ,
		Dot, 		// .
		DotDot,		// ..
		DotDotDot,	// ...
		Semi, 		// ;
		LParen, 	// (
		RParen,		// )
		LBracket, 	// [
		RBracket, 	// ]
		LCurly, 	// {
		RCurly, 	// }
		LArrow,		// <
		RArrow,		// >   
		Assign, 	// =
		AddAssign,	// +=
		SubAssign,	// -=
		MulAssign,	// *=
		DivAssign,	// /=
		ModAssign,	// %=
		LShiftAssign,	// >>=
		RShiftAssign,	// <<=
		BitAndAssign,	// &=
		BitXorAssign,	// ^=
		BitOrAssign,	// |=
		Bind, 		// =>
		Dollar, 	// $
		QuestionMark, 	// ?
		Tilde,		// ~ (BitwiseNot)
		Verbatim,	// @
		BitwiseOr, 	// |
		BitwiseAnd, // &
		BitwiseXor, // ^
		LShift, 	// <<
		//RShift, 	// >>
		NullCoarl, 	// ??
		NullCond,	// ?.
		Or, 		// ||
		And, 		// &&
		Increment,	// ++
		Decrement,	// --

	    EOF
	}
}
