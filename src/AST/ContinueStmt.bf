namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ContinueStmt : Statement
	{
		public Expression Target ~ delete _;
	}
}
