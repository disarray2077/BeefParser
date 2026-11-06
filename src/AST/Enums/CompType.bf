using System;
using BeefParser.AST;

namespace BeefParser.AST
{
	public enum CompType
	{
		Equal,
		StrictEqual,
		NotEqual,
		Greater,
		GreaterEqual,
		Lesser,
		LesserEqual,
		Spaceship,
		Case
	}

}

namespace BeefParser
{
	extension TokenType
	{
		public static implicit operator CompType(TokenType tokenType)
		{
			switch (tokenType)
			{
			case .Equal:
				return .Equal;
			case .StrictEqual:
				return .StrictEqual;
			case .NotEqual:
				return .NotEqual;
			case .RArrow:
				return .Greater;
			case .GreaterEq:
				return .GreaterEqual;
			case .LArrow:
				return .Lesser;
			case .LesserEq:
				return .LesserEqual;
			case .Spaceship:
				return .Spaceship;
			case .Case:
				return .Case;
			default:
				Runtime.NotImplemented();
			}
		}
	}
}