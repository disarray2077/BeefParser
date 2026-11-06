using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class DeclarationStmt : Statement
	{
		public bool IsConst;
		public bool IsStatic;
		public VariableDecl Declaration ~ Release!(_);
	}
}
