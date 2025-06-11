using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class UsingStmt : Statement
	{
		public VariableDecl Decl ~ delete _;
		public Expression Expr ~ delete _;
		public Statement Body ~ delete _;
	}
}
