namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class BitwiseOpExpr : Expression
	{
		public Expression Left ~ delete _;
		public TokenType Operation;
		public Expression Right ~ delete _;
	}
}
