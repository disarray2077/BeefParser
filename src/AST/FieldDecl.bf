using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class FieldDecl : MemberDecl
	{
		public VariableDecl Declaration ~ delete _;
	}
}