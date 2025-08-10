using System;
using System.Diagnostics;

namespace BeefParser.AST;

public abstract class ASTVisitor
{
	private mixin Visit(var x)
	{
		switch (x.Accept(this))
		{
		case .SkipAndContinue:
			return .Continue;
		case .Stop:
			return .Stop;
		case .Continue:
		}
	}

	public virtual VisitResult Visit(ASTNode node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(AttributedStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(CompoundStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(DeferStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(DoStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(UsingStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(IfStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(SwitchStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ForStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ForeachStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(WhileStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(RepeatStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(CompilationUnit node)
	{
		for (let decl in node.Declarations)
			Visit!(decl);
		return .Continue;
	}

	public virtual VisitResult Visit(NamespaceDecl node)
	{
		for (let decl in node.Declarations)
			Visit!(decl);
		return .Continue;
	}

	public virtual VisitResult Visit(ClassDecl node)
	{
		for (let decl in node.Declarations)
			Visit!(decl);
		return .Continue;
	}

	public virtual VisitResult Visit(StructDecl node)
	{
		for (let decl in node.Declarations)
			Visit!(decl);
		return .Continue;
	}

	public virtual VisitResult Visit(InterfaceDecl node)
	{
		for (let decl in node.Declarations)
			Visit!(decl);
		return .Continue;
	}

	public virtual VisitResult Visit(ExtensionDecl node)
	{
		for (let decl in node.Declarations)
			Visit!(decl);
		return .Continue;
	}

	public virtual VisitResult Visit(MethodDecl node)
	{
		Visit!(node.CompoundStmt);
		return .Continue;
	}

	public virtual VisitResult Visit(ReturnStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(DeclarationStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ExpressionStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(UsingDirective node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(EnumDecl node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(FieldDecl node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(PropertyDecl node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(IndexPropertyDecl node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(VariableDecl node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(DelegateDecl node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(NullLiteral node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(BoolLiteral node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(IntLiteral node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(RealLiteral node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(StrLiteral node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(CharLiteral node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(IdentifierExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(BinaryOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(BitwiseOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(LogicalOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(UnaryOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(PostfixOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ComparisonOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(MemberExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(MixinMemberExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(IndexOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(CallOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(TypeOfOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(SizeOfOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(DefaultOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(NewOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(NewArrayOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(NewArrayImplicitOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(AssignExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(CompoundAssignOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(BreakStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ContinueStmt node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(CastExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(RefExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(OutExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(GenericMemberExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ArrayInitExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ObjectInitExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(LambdaOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(VoidTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(DotTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(VarTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(LetTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ArrayTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(NullableTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(PointerTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(RefTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(DelegateTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(ExprModTypeSpec node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(SimpleName node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(IdentifierName node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(GenericName node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(QualifiedName node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(AttributedExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(NewInterpolatedStringOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(InterpolatedStringExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}
}