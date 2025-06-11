using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class IndexPropertyDecl : BasePropertyDecl
	{
		public List<ParamDecl> FormalParameters = new .() ~ Release!(_);
	}
}
