namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class VarExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}
