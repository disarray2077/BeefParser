namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class MemberExpr : Expression
	{
		public Expression Left ~ delete _;
		public Expression Right ~ delete _;
		public bool IsNullable = false;
	}
}
