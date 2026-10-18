using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class NewArrayOpExpr : Expression
	{
		public bool IsAppend;
		public bool IsScope;
		public bool IsRawAllocation; // The trailing '*' in new T[count]*
		public BindingSpec Bind ~ delete _;
		public ArrayTypeSpec TypeSpec ~ delete _;
		public ArrayInitExpr Initializer ~ delete _;
	}
}
