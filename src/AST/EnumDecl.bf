using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class EnumDecl : TypeDecl
	{
		public Dictionary<StringView, Expression> SimpleDeclarations = new .() ~ Release!(_);

		public bool IsSimpleEnum => !SimpleDeclarations.IsEmpty;
	}
}
