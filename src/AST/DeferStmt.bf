using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class DeferStmt : Statement
	{
		public BindingSpec Bind ~ delete _;
		public Statement Body ~ delete _;
	}
}
