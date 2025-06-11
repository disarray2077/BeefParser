namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class UnaryOpExpr : Expression
	{
		public TokenType Operation;
		public Expression Right ~ delete _;
	}
}
