using BeefParser.AST;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class InterpolatedStringExpr : Expression
	{
		public List<Expression> Exprs = new .() ~ Release!(_);
	}
}