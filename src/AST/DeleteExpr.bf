namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class DeleteOpExpr : Expression
	{
		public Expression Target ~ delete _;
		public Expression Expr ~ delete _;
	}
}
