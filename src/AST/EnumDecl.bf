using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class EnumDecl : TypeDecl
	{
		public Dictionary<String, Expression> SimpleDeclarations = new .() ~ Release!(_);

		public bool IsSimpleEnum => !SimpleDeclarations.IsEmpty;
	}
}
