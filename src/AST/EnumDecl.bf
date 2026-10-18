using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class EnumDecl : TypeDecl
	{
		public List<EnumMemberDecl> Members = new .() ~ Release!(_);

		public bool IsSimpleEnum => !Members.IsEmpty;
	}
}
