namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class BinaryOpExpr : Expression
	{
		public Expression Left ~ delete _;
		public TokenType Operation;
		public Expression Right ~ delete _;
	}
}
