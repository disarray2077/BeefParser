using System;
using System.Collections;

namespace BeefParser.AST
{
	abstract class TypeParameterConstraint : ASTNode
	{
		public virtual StringView Text => String.Empty;
	}

	abstract class ClassOrStructConstraint : TypeParameterConstraint
	{
	}

	[ImplementAccept, ImplementToString]
	class ClassConstraint : ClassOrStructConstraint
	{
		public override StringView Text => "class";
	}
	
	[ImplementAccept, ImplementToString]
	class StructConstraint : ClassOrStructConstraint
	{
		public override StringView Text => "struct";
	}
	
	[ImplementAccept, ImplementToString]
	class ConstructorConstraint : TypeParameterConstraint
	{
		public override StringView Text => "new";
	}
	
	[ImplementAccept, ImplementToString]
	class DestructorConstraint : TypeParameterConstraint
	{
		public override StringView Text => "delete";
	}
	
	[ImplementAccept, ImplementToString]
	class DefaultConstraint : TypeParameterConstraint
	{
		public override StringView Text => "default";
	}
	
	[ImplementAccept, ImplementToString]
	class TypeConstraint : TypeParameterConstraint
	{
		public TypeSpec TypeSpec ~ delete _;
	}
	
	[ImplementAccept, ImplementToString]
	class TypeBinaryOpConstraint : TypeParameterConstraint
	{
		public TypeSpec Left ~ delete _;
		public TokenType Operation;
		public TypeSpec Right ~ delete _;
	}
	
	[ImplementAccept, ImplementToString]
	class GenericConstraintDecl : ASTNode
	{
		public String mTarget ~ delete _;
		public List<TypeParameterConstraint> Constraints = new .() ~ Release!(_);

		public StringView Target
		{
			get => mTarget;
			set => String.NewOrSet!(mTarget, value);
		}
	}
}
