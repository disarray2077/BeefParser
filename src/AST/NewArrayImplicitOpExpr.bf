namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NewArrayImplicitOpExpr : Expression
	{
		public bool IsAppend;
		public bool IsScope;
		public BindingSpec Bind ~ delete _;
		public int CommaCount;
		public ArrayInitExpr Initializer ~ delete _;
	}
}