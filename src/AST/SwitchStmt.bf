using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class SwitchStmt : Statement
	{
		public Expression Expr ~ delete _;
		public List<SwitchSection> Sections = new .() ~ Release!(_);
		public SwitchSection DefaultSection ~ delete _;
	}
	
	[ImplementAccept, ImplementToString]
	public class SwitchSection : ASTNode
	{
		public List<Expression> Exprs = new .() ~ Release!(_);
		public Expression WhenExpr ~ delete _;
		public List<Statement> Body = new .() ~ Release!(_);
	}
}
