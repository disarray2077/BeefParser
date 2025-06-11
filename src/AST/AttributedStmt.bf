using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class AttributedStmt : Statement
	{
		public List<AttributeSpec> Attributes = new .() ~ Release!(_);
		public Statement Statement ~ delete _;
	}
}
