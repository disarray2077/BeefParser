using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class IfStmt : Statement
	{
		public Expression Condition ~ delete _;
		public Statement ThenStatement ~ delete _;
		public Statement ElseStatement ~ delete _;
	}
}
