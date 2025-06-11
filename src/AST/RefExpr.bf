namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class RefExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}
