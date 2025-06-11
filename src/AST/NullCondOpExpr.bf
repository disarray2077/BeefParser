namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NullCondOpExpr : Expression
	{
		public Expression Expr ~ delete _;
		public Expression NullExpr ~ delete _;
	}
}
