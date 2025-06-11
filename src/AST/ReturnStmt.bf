namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ReturnStmt : Statement
	{
		public Expression Expr ~ delete _;
	}
}
