namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class AddressOfExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}