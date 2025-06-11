using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class IndexOpExpr : Expression
	{
		public Expression Left ~ delete _;
		public List<Expression> Indexes = new .() ~ Release!(_);
	}
}
