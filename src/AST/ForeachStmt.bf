using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ForeachStmt : Statement
	{
		public TypeSpec TargetType ~ delete _;
		private String mTargetName ~ delete _;
		public Expression SourceExpr ~ delete _;
		public Statement Body ~ delete _;

		public StringView TargetName
		{
			get => mTargetName;
			set => String.NewOrSet!(mTargetName, value);
		}
	}
}
