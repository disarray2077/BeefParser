using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NewOpExpr : Expression
	{
		public bool IsAppend; // append .()
		public bool IsScope; // scope .()
		public BindingSpec Bind ~ delete _;
		public bool IsInplace; // .()
		public TypeSpec TypeSpec ~ delete _;
		public List<Expression> Arguments ~ Release!(_);
		public InitializerExpr Initializer ~ delete _;
	}
}
