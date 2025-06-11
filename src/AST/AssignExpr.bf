namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class AssignExpr : Expression
	{
		public Expression Left ~ delete _;
		public Expression Right ~ delete _;
	}
}
