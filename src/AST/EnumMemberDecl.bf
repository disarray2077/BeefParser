using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class EnumMemberDecl : Declaration
	{
		private String mName ~ delete _;
		public Expression Initializer ~ delete _;

		public StringView Name
		{
			get => mName;
			set => String.NewOrSet!(mName, value);
		}
	}
}
