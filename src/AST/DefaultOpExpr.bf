namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class DefaultOpExpr : Expression
	{
		public TypeSpec TypeSpec ~ delete _;
	}
}
