namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class LocalMethodStmt : Statement
	{
		public MethodDecl MethodDeclaration ~ delete _;
	}
}
