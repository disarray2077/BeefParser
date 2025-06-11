namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class TypeOfOpExpr : Expression
	{
		public TypeSpec TypeSpec ~ delete _;
	}
}
