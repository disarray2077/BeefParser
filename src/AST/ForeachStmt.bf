using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ForeachStmt : Statement
	{
		public bool IsAnonymous = false; // for (collection) without an explicit iteration variable.
		public TypeSpec TargetType ~ delete _;
		public Expression Binding ~ delete _;
		public Expression SourceExpr ~ delete _;
		public Statement Body ~ delete _;
	}
}
