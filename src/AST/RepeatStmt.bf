namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class RepeatStmt : Statement
	{
		public Expression Condition ~ delete _;
		public Statement Body ~ delete _;
	}
}
