namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class CompoundAssignOpExpr : Expression
	{
		public Expression Left ~ delete _;
		public TokenType Operation;
		public Expression Right ~ delete _;
	}
}
