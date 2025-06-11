using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class CastExpr : Expression
	{
		public TypeSpec TypeSpec ~ delete _;
		public Expression Expr ~ delete _;
	}
}
