using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NewOpExpr : Expression
	{
		public bool IsAppend; // append .()
		public bool IsScope; // scope .()
		public BindType Bind ~ if (Bind case .Custom(let bindExpr)) delete bindExpr;
		public bool IsInplace; // .()
		public TypeSpec TypeSpec ~ delete _;
		public List<Expression> Arguments ~ Release!(_);
		public InitializerExpr Initializer ~ delete _;
	}
}
