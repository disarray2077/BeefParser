namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class LetExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}
