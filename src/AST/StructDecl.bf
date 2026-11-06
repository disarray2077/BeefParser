using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class StructDecl : TypeDecl
	{
		public bool HasPrimaryConstructor;
		public bool IsOpaque;
		public List<ParamDecl> PrimaryConstructorParameters = new .() ~ Release!(_);
	}
}
