using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class DeferStmt : Statement
	{
		public BindType Bind ~ if (Bind case .Custom(let bindExpr)) delete bindExpr;
		public Statement Body ~ delete _;
	}
}
