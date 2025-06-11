namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class CondOpExpr : Expression
	{
		public Expression Expr ~ delete _;
		public Expression TrueExpr ~ delete _;
		public Expression FalseExpr ~ delete _;
	}
}
