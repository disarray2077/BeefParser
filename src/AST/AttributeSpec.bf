using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class AttributeSpec : ASTNode
	{
		public bool IsReturn;
		public bool IsAssembly;
		public TypeSpec TypeSpec ~ delete _;
		public List<Expression> Arguments = new .() ~ Release!(_);
	}
}
