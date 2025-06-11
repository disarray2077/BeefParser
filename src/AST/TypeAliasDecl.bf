using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class TypeAliasDecl : BaseTypeDecl
	{
		public List<String> GenericParametersNames = new .() ~ Release!(_);
		public TypeSpec TypeSpec ~ delete _;
	}
}
