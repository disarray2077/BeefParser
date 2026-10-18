namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class BindingSpec : ASTNode
	{
		public BindType Kind;
		public Expression Target ~ delete _;
	}
}
