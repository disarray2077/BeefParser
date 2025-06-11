namespace BeefParser.AST
{
	enum Modifier
	{
		None 		= 0,
		Abstract 	= 1 << 0,
		Const		= 1 << 1,
		Extern		= 1 << 2,
		Override	= 1 << 3,
		New			= 1 << 4,
		Partial		= 1 << 5,
		ReadOnly	= 1 << 6,
		Sealed		= 1 << 7,
		Unsafe		= 1 << 8,
		Virtual		= 1 << 9,
		Volatile	= 1 << 10,
		Static		= 1 << 11
	}
}
