namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class SizeOfOpExpr : Expression
	{
		public TypeSpec TypeSpec ~ delete _;
	}
}
