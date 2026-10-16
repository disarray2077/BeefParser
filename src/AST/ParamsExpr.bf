namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ParamsExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}
