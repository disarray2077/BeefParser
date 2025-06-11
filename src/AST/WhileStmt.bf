using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class WhileStmt : Statement
	{
		public Expression Condition ~ delete _;
		public Statement Body ~ delete _;
	}
}
