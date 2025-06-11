using System.Collections;

namespace BeefParser.AST
{
	abstract class InitializerExpr : Expression
	{
	}
	
	[ImplementAccept, ImplementToString]
	public class ArrayInitExpr : InitializerExpr
	{
		public List<Expression> Values = new .() ~ Release!(_);
	}
	
	[ImplementAccept, ImplementToString]
	public class ObjectInitExpr : InitializerExpr
	{
		public List<AssignExpr> Initializers = new .() ~ Release!(_);
	}
}