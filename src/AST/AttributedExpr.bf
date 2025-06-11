using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class AttributedExpr : Expression
	{
		public List<AttributeSpec> Attributes = new .() ~ Release!(_);
		public Expression Expr ~ delete _;
	}
}
