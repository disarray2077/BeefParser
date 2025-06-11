using System;
using BeefParser.AST;

namespace BeefParser.AST
{
	public enum BindType
	{
		case Undefined;
		case RootScope;
		case Mixin;
		case Custom(Expression bindExpr);
	}
}