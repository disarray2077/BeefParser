using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NewArrayOpExpr : Expression
	{
		public bool IsAppend;
		public bool IsScope;
		public BindType Bind ~ if (Bind case .Custom(let bindExpr)) delete bindExpr;
		public ArrayTypeSpec TypeSpec ~ delete _; // TypeSpec can be null when it's an implictly-typed array.
		public ArrayInitExpr Initializer ~ delete _;
	}
}
