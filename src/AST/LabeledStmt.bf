using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class LabeledStmt : Statement
	{
		public String mLabel ~ delete _;
		public Statement Statement ~ delete _;

		public StringView Label
		{
			get => mLabel;
			set => String.NewOrSet!(mLabel, value);
		}
	}
}
