namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class DoStmt : Statement
	{
		public Statement Body ~ delete _;
	}
}
