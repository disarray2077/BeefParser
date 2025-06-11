using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	public class PropertyAccessor : ASTNode
	{
		public enum AccessorType
		{
			Get,
			Set
		}
	
		public List<AttributeSpec> Attributes ~ Release!(_);
		public AccessLevel AccessLevel;
		public AccessorType AccessorType;
		public Statement Statement ~ delete _;
		public Expression Expr ~ delete _;
	
		public this(AccessLevel level)
		{
			AccessLevel = level;
		}
	}
}