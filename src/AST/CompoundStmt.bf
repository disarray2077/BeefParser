using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class CompoundStmt : Statement
	{
		public List<Statement> Statements = new .() ~ Release!(_);
	}
}
