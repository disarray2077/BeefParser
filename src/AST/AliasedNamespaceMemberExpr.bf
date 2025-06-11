using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class AliasedNamespaceMemberExpr : Expression
	{
		public IdentifierExpr Alias ~ delete _;
		public Expression Right ~ delete _;
	}
}
