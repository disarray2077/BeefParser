using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NewLambdaOpExpr : Expression
	{
		public bool IsAppend;
		public bool IsScope;
		public BindType Bind ~ if (Bind case .Custom(let bindExpr)) delete bindExpr;
		public Expression Expr ~ delete _;
	}
}
