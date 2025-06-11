namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NewArrayImplicitOpExpr : Expression
	{
		public bool IsAppend;
		public bool IsScope;
		public BindType Bind ~ if (Bind case .Custom(let bindExpr)) delete bindExpr;
		public int CommaCount;
		public ArrayInitExpr Initializer ~ delete _;
	}
}