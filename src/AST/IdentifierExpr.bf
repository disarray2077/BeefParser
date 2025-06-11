using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class IdentifierExpr : Expression
	{
		private String mValue ~ delete _;

		public StringView Value
		{
			get => mValue;
			set => String.NewOrSet!(mValue, value);
		}

		public this()
		{
		}

		public this(StringView value)
		{
			Value = value;
		}
	}
}
