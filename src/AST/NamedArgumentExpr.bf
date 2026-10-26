using System;

namespace BeefParser.AST;

[ImplementAccept, ImplementToString]
class NamedArgumentExpr : Expression
{
	public String Name ~ delete _;
	public Expression Value ~ delete _;
}
