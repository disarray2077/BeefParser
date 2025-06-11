namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class OutExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}
