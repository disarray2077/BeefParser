namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class CascadeMemberExpr : Expression
	{
		public Expression Left ~ delete _;
		public Expression Right ~ delete _;
	}
}
