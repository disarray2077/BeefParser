using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class GenericMemberExpr : Expression
	{
		public Expression Left ~ delete _;
		public bool IsNullable = false;
		public List<TypeSpec> GenericParameters ~ Release!(_);
	}
}
