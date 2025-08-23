using System;
using System.Collections;
using System.Diagnostics;

using internal BeefParser;

namespace BeefParser.AST
{
	abstract class TypeSpec : ASTNode
	{
	}
	
	[ImplementAccept, ImplementToString]
	class VoidTypeSpec : TypeSpec
	{
	}
	
	[ImplementAccept, ImplementToString]
	class DotTypeSpec : TypeSpec
	{
	}
	
	[ImplementAccept, ImplementToString]
	class VarTypeSpec : TypeSpec
	{
	}
	
	[ImplementAccept, ImplementToString]
	class LetTypeSpec : TypeSpec
	{
	}

	abstract class ElementedTypeSpec : TypeSpec
	{
		public TypeSpec Element ~ delete _;
	}
	
	[ImplementAccept, ImplementToString]
	class ArrayTypeSpec : ElementedTypeSpec
	{
		public int Dimensions;
		public List<Expression> Sizes = new .() ~ Release!(_); // Size can be null when the size should be inferred
	}
	
	[ImplementAccept, ImplementToString]
	class NullableTypeSpec : ElementedTypeSpec
	{
	}
	
	[ImplementAccept, ImplementToString]
	class PointerTypeSpec : ElementedTypeSpec
	{
	}
	
	[ImplementAccept, ImplementToString]
	class RefTypeSpec : ElementedTypeSpec
	{
	}
	
	[ImplementAccept, ImplementToString]
	class DelegateTypeSpec : TypeSpec
	{
		public TokenType Type;
		public TypeSpec ReturnType ~ delete _;
		public List<ParamDecl> Params = new .() ~ Release!(_);
	}

	[ImplementAccept, ImplementToString]
	class ExprModTypeSpec : TypeSpec
	{
		public TokenType Type;
		public Expression Expr;
	}
	
	[ImplementAccept, ImplementToString]
	public class TupleTypeSpec : TypeSpec
	{
	    public class Element
	    {
	        public TypeSpec Specification ~ delete _;
	        private String mName ~ delete _;

			public StringView Name
			{
				get => mName;
				set => String.NewOrSet!(mName, value);
			}
	    }

	    public List<Element> Elements = new .() ~ Release!(_);
	}
}