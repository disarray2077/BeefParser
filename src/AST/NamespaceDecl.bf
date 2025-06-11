using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NamespaceDecl : Declaration
	{
		public Name Name ~ delete _;
		public List<UsingDirective> Usings = new .() ~ Release!(_);
		public List<Declaration> Declarations = new .() ~ Release!(_);
	}
}
