using BeefParser.AST;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class InterpolatedStringExpr : Expression
	{
		public int BraceCount;
		public List<Expression> Exprs = new .() ~ Release!(_);

		public this(int braceCount)
		{
			BraceCount = braceCount;
		}
	}
}