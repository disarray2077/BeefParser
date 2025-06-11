namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class PointerIndirectionExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}