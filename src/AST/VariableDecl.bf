using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class VariableDecl : ASTNode
	{
		public TypeSpec Specification ~ delete _;
		public List<VariableDeclarator> Variables = new .() ~ Release!(_);
	}

	[ImplementAccept, ImplementToString]
	public class VariableDeclarator : ASTNode
	{
		private String mName ~ delete _;
		public Expression Initializer ~ delete _;
		public Statement Finalizer ~ delete _;

		public StringView Name
		{
			get => mName;
			set => String.NewOrSet!(mName, value);
		}
	}
}
