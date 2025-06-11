namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class BreakStmt : Statement
	{
		public Expression Target ~ delete _;
	}
}
