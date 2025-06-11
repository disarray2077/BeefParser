using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class CallOpExpr : Expression
	{
		public Expression Expr ~ delete _;
		public List<Expression> Params = new .() ~ Release!(_);
	}
}
