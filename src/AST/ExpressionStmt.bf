namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ExpressionStmt : Statement
	{
		public Expression Expr ~ delete _;
	}
}
