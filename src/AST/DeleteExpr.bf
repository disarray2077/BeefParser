namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class DeleteOpExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}
