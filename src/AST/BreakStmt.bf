using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class BreakStmt : Statement
	{
		public StringView TargetLabel;
	}
}
