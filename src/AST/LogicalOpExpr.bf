namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class LogicalOpExpr : Expression
	{
		public Expression Left ~ delete _;
		public TokenType Operation;
		public Expression Right ~ delete _;
	}
}
