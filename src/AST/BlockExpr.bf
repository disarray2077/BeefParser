using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	public class BlockExpr : Expression
	{
	    public List<Statement> Statements = new .() ~ Release!(_);
	    public Expression ResultExpr ~ delete _;
	}
}
