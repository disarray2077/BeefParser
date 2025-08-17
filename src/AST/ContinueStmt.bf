using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ContinueStmt : Statement
	{
		public StringView TargetLabel;
	}
}
