using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class ParamDecl : ASTNode
	{
		public List<AttributeSpec> Attributes ~ Release!(_);
		public bool IsIn;
		public bool IsOut;
		public bool IsRef;
		public TypeSpec Specification ~ delete _;
		public String mName ~ delete _;
		public Expression Default ~ delete _;

		public StringView Name
		{
			get => mName;
			set => String.NewOrSet!(mName, value);
		}
	}
}
