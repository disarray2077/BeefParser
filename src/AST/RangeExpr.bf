namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class RangeExpr : Expression
	{
		public Expression Left ~ delete _;
		public Expression Right ~ delete _;
		public TokenType Type;
	}
}
