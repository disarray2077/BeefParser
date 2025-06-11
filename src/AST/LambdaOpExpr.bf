using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class LambdaOpExpr : Expression
	{
		public List<String> FormalParameters ~ Release!(_);
		public Statement Statement ~ delete _;
		public Expression Expr ~ delete _;
	}
}
