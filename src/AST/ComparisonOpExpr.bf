using System;
using BeefParser.AST;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ComparisonOpExpr : Expression
	{
		public CompType Type;
		public Expression Left ~ delete _;
		public Expression Right ~ delete _;
	}
}
