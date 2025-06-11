using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class MixinMemberExpr : Expression
	{
		public Expression Expr ~ delete _;
	}
}
