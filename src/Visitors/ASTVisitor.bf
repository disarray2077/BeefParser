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

	public virtual VisitResult Visit(LabeledStmt node)
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

	public virtual VisitResult Visit(MixinDecl node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(MethodDecl node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
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

	public virtual VisitResult Visit(TypeAliasDecl node)
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

	public virtual VisitResult Visit(CascadeMemberExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(AliasedNamespaceMemberExpr node)
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

	public virtual VisitResult Visit(FallthroughStmt node)
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

	public virtual VisitResult Visit(VarExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(LetExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(PointerIndirectionExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(AddressOfExpr node)
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

	public virtual VisitResult Visit(NewLambdaOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(InterpolatedStringExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(RangeExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(DeleteOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(CondOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(NullCondOpExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(UninitializedExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}

	public virtual VisitResult Visit(BlockExpr node)
	{
		Debug.WriteLine(scope $"No visitor implemented for '{node.GetType()}'");
		return .Continue;
	}
}

public interface IASTVisitorWithCustomResult
{
	protected typealias TResult = Object;
	public virtual TResult Visit(ASTNode node) => default;
	public virtual TResult Visit(CompilationUnit node) => default;
	public virtual TResult Visit(NamespaceDecl node) => default;
	public virtual TResult Visit(ClassDecl node) => default;
	public virtual TResult Visit(StructDecl node) => default;
	public virtual TResult Visit(InterfaceDecl node) => default;
	public virtual TResult Visit(ExtensionDecl node) => default;
	public virtual TResult Visit(MixinDecl node) => default;
	public virtual TResult Visit(MethodDecl node) => default;
	public virtual TResult Visit(AttributedStmt node) => default;
	public virtual TResult Visit(CompoundStmt node) => default;
	public virtual TResult Visit(DeferStmt node) => default;
	public virtual TResult Visit(DoStmt node) => default;
	public virtual TResult Visit(UsingStmt node) => default;
	public virtual TResult Visit(IfStmt node) => default;
	public virtual TResult Visit(SwitchStmt node) => default;
	public virtual TResult Visit(LabeledStmt node) => default;
	public virtual TResult Visit(ForStmt node) => default;
	public virtual TResult Visit(ForeachStmt node) => default;
	public virtual TResult Visit(WhileStmt node) => default;
	public virtual TResult Visit(RepeatStmt node) => default;
	public virtual TResult Visit(ReturnStmt node) => default;
	public virtual TResult Visit(DeclarationStmt node) => default;
	public virtual TResult Visit(ExpressionStmt node) => default;
	public virtual TResult Visit(UsingDirective node) => default;
	public virtual TResult Visit(EnumDecl node) => default;
	public virtual TResult Visit(TypeAliasDecl node) => default;
	public virtual TResult Visit(FieldDecl node) => default;
	public virtual TResult Visit(PropertyDecl node) => default;
	public virtual TResult Visit(IndexPropertyDecl node) => default;
	public virtual TResult Visit(VariableDecl node) => default;
	public virtual TResult Visit(DelegateDecl node) => default;
	public virtual TResult Visit(NullLiteral node) => default;
	public virtual TResult Visit(BoolLiteral node) => default;
	public virtual TResult Visit(IntLiteral node) => default;
	public virtual TResult Visit(RealLiteral node) => default;
	public virtual TResult Visit(StrLiteral node) => default;
	public virtual TResult Visit(CharLiteral node) => default;
	public virtual TResult Visit(IdentifierExpr node) => default;
	public virtual TResult Visit(BinaryOpExpr node) => default;
	public virtual TResult Visit(BitwiseOpExpr node) => default;
	public virtual TResult Visit(LogicalOpExpr node) => default;
	public virtual TResult Visit(UnaryOpExpr node) => default;
	public virtual TResult Visit(PostfixOpExpr node) => default;
	public virtual TResult Visit(ComparisonOpExpr node) => default;
	public virtual TResult Visit(MemberExpr node) => default;
	public virtual TResult Visit(CascadeMemberExpr node) => default;
	public virtual TResult Visit(AliasedNamespaceMemberExpr node) => default;
	public virtual TResult Visit(MixinMemberExpr node) => default;
	public virtual TResult Visit(IndexOpExpr node) => default;
	public virtual TResult Visit(CallOpExpr node) => default;
	public virtual TResult Visit(TypeOfOpExpr node) => default;
	public virtual TResult Visit(SizeOfOpExpr node) => default;
	public virtual TResult Visit(DefaultOpExpr node) => default;
	public virtual TResult Visit(NewOpExpr node) => default;
	public virtual TResult Visit(NewArrayOpExpr node) => default;
	public virtual TResult Visit(NewArrayImplicitOpExpr node) => default;
	public virtual TResult Visit(AssignExpr node) => default;
	public virtual TResult Visit(CompoundAssignOpExpr node) => default;
	public virtual TResult Visit(BreakStmt node) => default;
	public virtual TResult Visit(ContinueStmt node) => default;
	public virtual TResult Visit(CastExpr node) => default;
	public virtual TResult Visit(RefExpr node) => default;
	public virtual TResult Visit(OutExpr node) => default;
	public virtual TResult Visit(VarExpr node) => default;
	public virtual TResult Visit(LetExpr node) => default;
	public virtual TResult Visit(PointerIndirectionExpr node) => default;
	public virtual TResult Visit(AddressOfExpr node) => default;
	public virtual TResult Visit(GenericMemberExpr node) => default;
	public virtual TResult Visit(ArrayInitExpr node) => default;
	public virtual TResult Visit(ObjectInitExpr node) => default;
	public virtual TResult Visit(LambdaOpExpr node) => default;
	public virtual TResult Visit(VoidTypeSpec node) => default;
	public virtual TResult Visit(DotTypeSpec node) => default;
	public virtual TResult Visit(VarTypeSpec node) => default;
	public virtual TResult Visit(LetTypeSpec node) => default;
	public virtual TResult Visit(ArrayTypeSpec node) => default;
	public virtual TResult Visit(NullableTypeSpec node) => default;
	public virtual TResult Visit(PointerTypeSpec node) => default;
	public virtual TResult Visit(RefTypeSpec node) => default;
	public virtual TResult Visit(DelegateTypeSpec node) => default;
	public virtual TResult Visit(ExprModTypeSpec node) => default;
	public virtual TResult Visit(SimpleName node) => default;
	public virtual TResult Visit(IdentifierName node) => default;
	public virtual TResult Visit(GenericName node) => default;
	public virtual TResult Visit(QualifiedName node) => default;
	public virtual TResult Visit(AttributedExpr node) => default;
	public virtual TResult Visit(NewInterpolatedStringOpExpr node) => default;
	public virtual TResult Visit(NewLambdaOpExpr node) => default;
	public virtual TResult Visit(InterpolatedStringExpr node) => default;
	public virtual TResult Visit(RangeExpr node) => default;
	public virtual TResult Visit(DeleteOpExpr node) => default;
	public virtual TResult Visit(CondOpExpr node) => default;
	public virtual TResult Visit(NullCondOpExpr node) => default;
	public virtual TResult Visit(UninitializedExpr node) => default;
	public virtual TResult Visit(BlockExpr node) => default;
}

public abstract class ASTVisitor<TResult> : IASTVisitorWithCustomResult
{
	public TResult Visit(ASTNode node)
	{
		if (node != null)
			return (TResult)node.AcceptWithCustomResult(this);
		return default;
	}

	public virtual TResult Visit(CompilationUnit node) => default;
	public virtual TResult Visit(NamespaceDecl node) => default;
	public virtual TResult Visit(ClassDecl node) => default;
	public virtual TResult Visit(StructDecl node) => default;
	public virtual TResult Visit(InterfaceDecl node) => default;
	public virtual TResult Visit(ExtensionDecl node) => default;
	public virtual TResult Visit(MixinDecl node) => default;
	public virtual TResult Visit(MethodDecl node) => default;
	public virtual TResult Visit(AttributedStmt node) => default;
	public virtual TResult Visit(CompoundStmt node) => default;
	public virtual TResult Visit(DeferStmt node) => default;
	public virtual TResult Visit(DoStmt node) => default;
	public virtual TResult Visit(UsingStmt node) => default;
	public virtual TResult Visit(IfStmt node) => default;
	public virtual TResult Visit(SwitchStmt node) => default;
	public virtual TResult Visit(LabeledStmt node) => default;
	public virtual TResult Visit(ForStmt node) => default;
	public virtual TResult Visit(ForeachStmt node) => default;
	public virtual TResult Visit(WhileStmt node) => default;
	public virtual TResult Visit(RepeatStmt node) => default;
	public virtual TResult Visit(ReturnStmt node) => default;
	public virtual TResult Visit(DeclarationStmt node) => default;
	public virtual TResult Visit(ExpressionStmt node) => default;
	public virtual TResult Visit(UsingDirective node) => default;
	public virtual TResult Visit(EnumDecl node) => default;
	public virtual TResult Visit(TypeAliasDecl node) => default;
	public virtual TResult Visit(FieldDecl node) => default;
	public virtual TResult Visit(PropertyDecl node) => default;
	public virtual TResult Visit(IndexPropertyDecl node) => default;
	public virtual TResult Visit(VariableDecl node) => default;
	public virtual TResult Visit(DelegateDecl node) => default;
	public virtual TResult Visit(NullLiteral node) => default;
	public virtual TResult Visit(BoolLiteral node) => default;
	public virtual TResult Visit(IntLiteral node) => default;
	public virtual TResult Visit(RealLiteral node) => default;
	public virtual TResult Visit(StrLiteral node) => default;
	public virtual TResult Visit(CharLiteral node) => default;
	public virtual TResult Visit(IdentifierExpr node) => default;
	public virtual TResult Visit(BinaryOpExpr node) => default;
	public virtual TResult Visit(BitwiseOpExpr node) => default;
	public virtual TResult Visit(LogicalOpExpr node) => default;
	public virtual TResult Visit(UnaryOpExpr node) => default;
	public virtual TResult Visit(PostfixOpExpr node) => default;
	public virtual TResult Visit(ComparisonOpExpr node) => default;
	public virtual TResult Visit(MemberExpr node) => default;
	public virtual TResult Visit(CascadeMemberExpr node) => default;
	public virtual TResult Visit(AliasedNamespaceMemberExpr node) => default;
	public virtual TResult Visit(MixinMemberExpr node) => default;
	public virtual TResult Visit(IndexOpExpr node) => default;
	public virtual TResult Visit(CallOpExpr node) => default;
	public virtual TResult Visit(TypeOfOpExpr node) => default;
	public virtual TResult Visit(SizeOfOpExpr node) => default;
	public virtual TResult Visit(DefaultOpExpr node) => default;
	public virtual TResult Visit(NewOpExpr node) => default;
	public virtual TResult Visit(NewArrayOpExpr node) => default;
	public virtual TResult Visit(NewArrayImplicitOpExpr node) => default;
	public virtual TResult Visit(AssignExpr node) => default;
	public virtual TResult Visit(CompoundAssignOpExpr node) => default;
	public virtual TResult Visit(BreakStmt node) => default;
	public virtual TResult Visit(ContinueStmt node) => default;
	public virtual TResult Visit(CastExpr node) => default;
	public virtual TResult Visit(RefExpr node) => default;
	public virtual TResult Visit(OutExpr node) => default;
	public virtual TResult Visit(VarExpr node) => default;
	public virtual TResult Visit(LetExpr node) => default;
	public virtual TResult Visit(PointerIndirectionExpr node) => default;
	public virtual TResult Visit(AddressOfExpr node) => default;
	public virtual TResult Visit(GenericMemberExpr node) => default;
	public virtual TResult Visit(ArrayInitExpr node) => default;
	public virtual TResult Visit(ObjectInitExpr node) => default;
	public virtual TResult Visit(LambdaOpExpr node) => default;
	public virtual TResult Visit(VoidTypeSpec node) => default;
	public virtual TResult Visit(DotTypeSpec node) => default;
	public virtual TResult Visit(VarTypeSpec node) => default;
	public virtual TResult Visit(LetTypeSpec node) => default;
	public virtual TResult Visit(ArrayTypeSpec node) => default;
	public virtual TResult Visit(NullableTypeSpec node) => default;
	public virtual TResult Visit(PointerTypeSpec node) => default;
	public virtual TResult Visit(RefTypeSpec node) => default;
	public virtual TResult Visit(DelegateTypeSpec node) => default;
	public virtual TResult Visit(ExprModTypeSpec node) => default;
	public virtual TResult Visit(SimpleName node) => default;
	public virtual TResult Visit(IdentifierName node) => default;
	public virtual TResult Visit(GenericName node) => default;
	public virtual TResult Visit(QualifiedName node) => default;
	public virtual TResult Visit(AttributedExpr node) => default;
	public virtual TResult Visit(NewInterpolatedStringOpExpr node) => default;
	public virtual TResult Visit(NewLambdaOpExpr node) => default;
	public virtual TResult Visit(InterpolatedStringExpr node) => default;
	public virtual TResult Visit(RangeExpr node) => default;
	public virtual TResult Visit(DeleteOpExpr node) => default;
	public virtual TResult Visit(CondOpExpr node) => default;
	public virtual TResult Visit(NullCondOpExpr node) => default;
	public virtual TResult Visit(UninitializedExpr node) => default;
	public virtual TResult Visit(BlockExpr node) => default;

#region Dispatch	
	public Object IASTVisitorWithCustomResult.Visit(ASTNode node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(CompilationUnit node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NamespaceDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ClassDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(StructDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(InterfaceDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ExtensionDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(MixinDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(MethodDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(AttributedStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(CompoundStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(DeferStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(DoStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(UsingStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(IfStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(SwitchStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(LabeledStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ForStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ForeachStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(WhileStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(RepeatStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ReturnStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(DeclarationStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ExpressionStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(UsingDirective node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(EnumDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(TypeAliasDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(FieldDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(PropertyDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(IndexPropertyDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(VariableDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(DelegateDecl node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NullLiteral node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(BoolLiteral node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(IntLiteral node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(RealLiteral node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(StrLiteral node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(CharLiteral node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(IdentifierExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(BinaryOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(BitwiseOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(LogicalOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(UnaryOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(PostfixOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ComparisonOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(MemberExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(CascadeMemberExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(AliasedNamespaceMemberExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(MixinMemberExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(IndexOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(CallOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(TypeOfOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(SizeOfOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(DefaultOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NewOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NewArrayOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NewArrayImplicitOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(AssignExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(CompoundAssignOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(BreakStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ContinueStmt node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(CastExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(RefExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(OutExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(VarExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(LetExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(PointerIndirectionExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(AddressOfExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(GenericMemberExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ArrayInitExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ObjectInitExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(LambdaOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(VoidTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(DotTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(VarTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(LetTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ArrayTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NullableTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(PointerTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(RefTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(DelegateTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(ExprModTypeSpec node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(SimpleName node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(IdentifierName node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(GenericName node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(QualifiedName node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(AttributedExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NewInterpolatedStringOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NewLambdaOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(InterpolatedStringExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(RangeExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(DeleteOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(CondOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(NullCondOpExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(UninitializedExpr node) => ((Self)this).Visit(node);
	public Object IASTVisitorWithCustomResult.Visit(BlockExpr node) => ((Self)this).Visit(node);
#endregion
}