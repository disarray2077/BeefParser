using System;
using System.Collections;

namespace BeefParser.AST
{
	abstract class TypeParameterConstraint : ASTNode
	{
		public virtual StringView Text => String.Empty;
	}

	[ImplementAccept, ImplementToString]
	class ConstConstraint : TypeParameterConstraint
	{
		public override StringView Text => "const";
	}

	[ImplementAccept, ImplementToString]
	class EnumConstraint : TypeParameterConstraint
	{
		public override StringView Text => "enum";
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
		public bool IsPointer;
		public override StringView Text => IsPointer ? "struct*" : "struct";
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
		public TypeSpec TargetType ~ delete _;
		public List<TypeParameterConstraint> Constraints = new .() ~ Release!(_);
	}
}
