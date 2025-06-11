using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ArgumentGroupExpr : Expression
	{
		public List<Expression> Arguments = new .() ~ Release!(_);
	}
}
