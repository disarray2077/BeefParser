using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class EnumDecl : BaseTypeDecl
	{
		public Dictionary<StringView, Expression> Declarations = new .() ~ Release!(_);
	}
}
