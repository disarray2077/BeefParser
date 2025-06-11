namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class PostfixOpExpr : Expression
	{
		public Expression Left ~ delete _;
		public TokenType Operation;
	}
}
