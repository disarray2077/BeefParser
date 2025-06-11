namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class CascadeOpExpr : Expression
	{
		public Expression Right ~ delete _;
	}
}
