using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ForStmt : Statement
	{
		public bool IsShortForm = false; // for ({X} < {Y})
		public VariableDecl Declaration ~ delete _;
		public List<Expression> Initializers ~ Release!(_);
		public Expression Condition ~ delete _;
		public List<Expression> Incrementors ~ Release!(_);
		public Statement Body ~ delete _;
	}
}
