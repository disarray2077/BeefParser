using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	public class TupleExpr : Expression
	{
	    public List<Expression> Elements = new .() ~ Release!(_);
	}
}
