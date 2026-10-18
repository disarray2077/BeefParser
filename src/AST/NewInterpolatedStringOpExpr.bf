using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NewInterpolatedStringOpExpr : Expression
	{
		public bool IsAppend;
		public bool IsScope;
		public BindingSpec Bind ~ delete _;
		public Expression Expr ~ delete _;
	}
}
