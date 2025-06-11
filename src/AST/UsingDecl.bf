namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class UsingDirective : ASTNode
	{
		public bool isInternal;
		public bool isStatic;
		public Name Name ~ delete _;
	}
}
