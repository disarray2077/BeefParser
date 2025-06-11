using System;
using BeefParser.AST;

namespace BeefParser.AST
{
	public enum RealType
	{
		Double,
		Float,
		Decimal
	}
}

namespace BeefParser
{
	extension TokenType
	{
		public static implicit operator RealType(TokenType tokenType)
		{
			switch (tokenType)
			{
			case .FloatLiteral:
				return .Float;
			case .DoubleLiteral:
				return .Double;
			default:
				Runtime.NotImplemented();
			}
		}
	}
}