using System;
using System.Collections;

namespace BeefParser.AST
{
    public class ASTWalker : ASTVisitor
    {
		public new VisitResult Visit(ASTNode node)
		{
			if (node != null)
				return node.Accept(this);
			return .Continue;
		}

        public virtual VisitResult Walk(ASTNode node)
        {
            if (node == null)
            {
                return VisitResult.Continue;
            }
            return Visit(node);
        }

        public VisitResult VisitList<T>(List<T> list) where T : ASTNode
        {
            if (list == null)
            {
                return VisitResult.Continue;
            }

            for (var node in list)
            {
                var result = Visit(node);
                if (result != VisitResult.Continue)
                {
                    return result;
                }
            }
            return VisitResult.Continue;
        }

        public VisitResult VisitDictionary(Dictionary<StringView, Expression> dict)
        {
            if (dict == null)
            {
                return VisitResult.Continue;
            }

            for (var value in dict.Values)
            {
                var result = Visit(value);
                if (result != VisitResult.Continue)
                {
                    return result;
                }
            }
            return VisitResult.Continue;
        }

        public override VisitResult Visit(CompilationUnit compilationUnit)
        {
            if (VisitList(compilationUnit.Usings) == VisitResult.Stop) return VisitResult.Stop;
            if (VisitList(compilationUnit.Declarations) == VisitResult.Stop) return VisitResult.Stop;
            return VisitResult.Continue;
        }

        public override VisitResult Visit(NamespaceDecl nsDecl)
        {
            return VisitList(nsDecl.Declarations);
        }

        public override VisitResult Visit(UsingDirective usingDecl) => VisitResult.Continue;

        public override VisitResult Visit(TypeAliasDecl typeAliasDecl)
        {
            return Visit(typeAliasDecl.TypeSpec);
        }

        public override VisitResult Visit(FieldDecl fieldDecl)
        {
            return Visit(fieldDecl.Declaration);
        }

        public override VisitResult Visit(PropertyDecl propertyDecl)
        {
            if (Visit(propertyDecl.Specification) == VisitResult.Stop) return VisitResult.Stop;
            if (Visit(propertyDecl.ExplicitInterfaceName) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(propertyDecl.Accessors);
        }

        public override VisitResult Visit(IndexPropertyDecl indexerDecl)
        {
            if (Visit(indexerDecl.Specification) == VisitResult.Stop) return VisitResult.Stop;
            if (Visit(indexerDecl.ExplicitInterfaceName) == VisitResult.Stop) return VisitResult.Stop;
            if (VisitList(indexerDecl.FormalParameters) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(indexerDecl.Accessors);
        }

        public override VisitResult Visit(VariableDecl varDecl)
        {
            if (Visit(varDecl.Specification) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(varDecl.Variables);
        }

        public override VisitResult Visit(ClassDecl classDecl)
        {
            return VisitList(classDecl.Declarations);
        }

        public override VisitResult Visit(StructDecl structDecl)
        {
            return VisitList(structDecl.Declarations);
        }

        public override VisitResult Visit(EnumDecl enumDecl)
        {
			if (enumDecl.IsSimpleEnum)
            	return VisitDictionary(enumDecl.SimpleDeclarations);
			else
				return VisitList(enumDecl.Declarations);
        }

        public override VisitResult Visit(DelegateDecl delDecl)
        {
            if (Visit(delDecl.Specification) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(delDecl.FormalParameters);
        }

        public override VisitResult Visit(MixinDecl mixinDecl)
        {
            if (VisitList(mixinDecl.FormalParameters) == VisitResult.Stop) return VisitResult.Stop;
            if (VisitList(mixinDecl.Statements) == VisitResult.Stop) return VisitResult.Stop;
			return Visit(mixinDecl.ReturnExpr);
        }

        public override VisitResult Visit(MethodDecl methodDecl)
        {
            if (Visit(methodDecl.Specification) == VisitResult.Stop) return VisitResult.Stop;
            if (VisitList(methodDecl.FormalParameters) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(methodDecl.CompoundStmt);
        }

        public override VisitResult Visit(NullLiteral nullConstExpr) => VisitResult.Continue;
        public override VisitResult Visit(BoolLiteral boolConstExpr) => VisitResult.Continue;
        public override VisitResult Visit(IntLiteral numConstExpr) => VisitResult.Continue;
        public override VisitResult Visit(RealLiteral numConstExpr) => VisitResult.Continue;
        public override VisitResult Visit(StrLiteral strConstExpr) => VisitResult.Continue;
        public override VisitResult Visit(CharLiteral chrConstExpr) => VisitResult.Continue;

        public override VisitResult Visit(AttributedStmt node)
        {
            return Visit(node.Statement);
        }

        public override VisitResult Visit(CompoundStmt compStmt)
        {
            return VisitList(compStmt.Statements);
        }

        public override VisitResult Visit(DeferStmt deferStmt)
        {
            return Visit(deferStmt.Body);
        }

        public override VisitResult Visit(DeclarationStmt declStmt)
        {
            return Visit(declStmt.Declaration);
        }

        public override VisitResult Visit(UsingStmt usingStmt)
        {
            if (Visit(usingStmt.Decl) == VisitResult.Stop) return VisitResult.Stop;
            if (Visit(usingStmt.Expr) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(usingStmt.Body);
        }

        public override VisitResult Visit(IfStmt ifStmt)
        {
            if (Visit(ifStmt.Condition) == VisitResult.Stop) return VisitResult.Stop;
            if (Visit(ifStmt.ThenStatement) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(ifStmt.ElseStatement);
        }

        public override VisitResult Visit(ForStmt forStmt)
        {
            if (VisitList(forStmt.Initializers) == VisitResult.Stop) return VisitResult.Stop;
            if (Visit(forStmt.Declaration) == VisitResult.Stop) return VisitResult.Stop;
            if (Visit(forStmt.Condition) == VisitResult.Stop) return VisitResult.Stop;
            if (VisitList(forStmt.Incrementors) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(forStmt.Body);
        }

        public override VisitResult Visit(ForeachStmt foreachStmt)
        {
            if (Visit(foreachStmt.TargetType) == VisitResult.Stop) return VisitResult.Stop;
            if (Visit(foreachStmt.SourceExpr) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(foreachStmt.Body);
        }

        public override VisitResult Visit(WhileStmt whileStmt)
        {
            if (Visit(whileStmt.Condition) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(whileStmt.Body);
        }

        public override VisitResult Visit(RepeatStmt repeatStmt)
        {
            if (Visit(repeatStmt.Body) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(repeatStmt.Condition);
        }

        public override VisitResult Visit(DoStmt doStmt)
        {
            return Visit(doStmt.Body);
        }

        public override VisitResult Visit(SwitchStmt switchStmt)
        {
            if (Visit(switchStmt.Expr) == VisitResult.Stop) return VisitResult.Stop;
            if (VisitList(switchStmt.Sections) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(switchStmt.DefaultSection);
        }

        public override VisitResult Visit(LabeledStmt labeledStmt)
        {
            return Visit(labeledStmt.Statement);
        }

        public override VisitResult Visit(IdentifierExpr identExpr) => VisitResult.Continue;

        public override VisitResult Visit(BinaryOpExpr binOpExpr)
        {
            if (Visit(binOpExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(binOpExpr.Right);
        }

        public override VisitResult Visit(BitwiseOpExpr bitOpExpr)
        {
            if (Visit(bitOpExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(bitOpExpr.Right);
        }

        public override VisitResult Visit(LogicalOpExpr logicalOpExpr)
        {
            if (Visit(logicalOpExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(logicalOpExpr.Right);
        }

        public override VisitResult Visit(UnaryOpExpr unaryOpExpr)
        {
            return Visit(unaryOpExpr.Right);
        }

        public override VisitResult Visit(PostfixOpExpr postfixOpExpr)
        {
            return Visit(postfixOpExpr.Left);
        }

        public override VisitResult Visit(ComparisonOpExpr compOpExpr)
        {
            if (Visit(compOpExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(compOpExpr.Right);
        }

        public override VisitResult Visit(MemberExpr memberExpr)
        {
            if (Visit(memberExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(memberExpr.Right);
        }

        public override VisitResult Visit(CascadeMemberExpr cascadeExpr)
        {
            if (Visit(cascadeExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(cascadeExpr.Right);
        }

        public override VisitResult Visit(AliasedNamespaceMemberExpr aliasedExpr)
        {
            if (Visit(aliasedExpr.Alias) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(aliasedExpr.Right);
        }

        public override VisitResult Visit(MixinMemberExpr memberExpr)
        {
            return Visit(memberExpr.Expr);
        }

        public override VisitResult Visit(IndexOpExpr indexOpExpr)
        {
            if (Visit(indexOpExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(indexOpExpr.Indexes);
        }

        public override VisitResult Visit(CallOpExpr callOpExpr)
        {
            if (Visit(callOpExpr.Expr) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(callOpExpr.Params);
        }

        public override VisitResult Visit(TypeOfOpExpr typeOfOpExpr)
        {
            return Visit(typeOfOpExpr.TypeSpec);
        }

        public override VisitResult Visit(SizeOfOpExpr sizeOfOpExpr)
        {
            return Visit(sizeOfOpExpr.TypeSpec);
        }

        public override VisitResult Visit(DefaultOpExpr defaultOpExpr)
        {
            return Visit(defaultOpExpr.TypeSpec);
        }

        public override VisitResult Visit(NewOpExpr newOpExpr)
        {
            if (Visit(newOpExpr.TypeSpec) == VisitResult.Stop) return VisitResult.Stop;
            if (VisitList(newOpExpr.Arguments) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(newOpExpr.Initializer);
        }

        public override VisitResult Visit(NewArrayOpExpr newArrayOpExpr)
        {
            if (Visit(newArrayOpExpr.TypeSpec) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(newArrayOpExpr.Initializer);
        }

        public override VisitResult Visit(NewArrayImplicitOpExpr newArrayImplicitOpExpr)
        {
            return Visit(newArrayImplicitOpExpr.Initializer);
        }

        public override VisitResult Visit(AssignExpr assignOpExpr)
        {
            if (Visit(assignOpExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(assignOpExpr.Right);
        }

        public override VisitResult Visit(CompoundAssignOpExpr cpdAssignOpExpr)
        {
            if (Visit(cpdAssignOpExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(cpdAssignOpExpr.Right);
        }

        public override VisitResult Visit(ReturnStmt retStmt)
        {
            return Visit(retStmt.Expr);
        }

        public override VisitResult Visit(BreakStmt brkStmt) => VisitResult.Continue;
        public override VisitResult Visit(ContinueStmt cntStmt) => VisitResult.Continue;

        public override VisitResult Visit(CastExpr castExpr)
        {
            if (Visit(castExpr.TypeSpec) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(castExpr.Expr);
        }

        public override VisitResult Visit(RefExpr refExpr)
        {
            return Visit(refExpr.Expr);
        }

        public override VisitResult Visit(OutExpr outExpr)
        {
            return Visit(outExpr.Expr);
        }

        public override VisitResult Visit(VarExpr varExpr)
        {
            return Visit(varExpr.Expr);
        }

        public override VisitResult Visit(LetExpr letExpr)
        {
            return Visit(letExpr.Expr);
        }

        public override VisitResult Visit(PointerIndirectionExpr ptrExpr)
        {
            return Visit(ptrExpr.Expr);
        }

        public override VisitResult Visit(AddressOfExpr addrExpr)
        {
            return Visit(addrExpr.Expr);
        }

        public override VisitResult Visit(GenericMemberExpr genMemberExpr)
        {
            if (Visit(genMemberExpr.Left) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(genMemberExpr.GenericParameters);
        }

        public override VisitResult Visit(ExpressionStmt exprStmt)
        {
            return Visit(exprStmt.Expr);
        }

        public override VisitResult Visit(ArrayInitExpr arrayInitExpr)
        {
            return VisitList(arrayInitExpr.Values);
        }

        public override VisitResult Visit(ObjectInitExpr objectInitExpr)
        {
            return VisitList(objectInitExpr.Initializers);
        }

        public override VisitResult Visit(LambdaOpExpr node)
        {
            if (Visit(node.Expr) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(node.Statement);
        }

        public override VisitResult Visit(VoidTypeSpec node) => VisitResult.Continue;
        public override VisitResult Visit(DotTypeSpec node) => VisitResult.Continue;
        public override VisitResult Visit(VarTypeSpec node) => VisitResult.Continue;
        public override VisitResult Visit(LetTypeSpec node) => VisitResult.Continue;

        public override VisitResult Visit(ArrayTypeSpec node)
        {
            if (Visit(node.Element) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(node.Sizes);
        }

        public override VisitResult Visit(NullableTypeSpec node)
        {
            return Visit(node.Element);
        }

        public override VisitResult Visit(PointerTypeSpec node)
        {
            return Visit(node.Element);
        }

        public override VisitResult Visit(RefTypeSpec node)
        {
            return Visit(node.Element);
        }

        public override VisitResult Visit(DelegateTypeSpec node)
        {
            if (Visit(node.ReturnType) == VisitResult.Stop) return VisitResult.Stop;
            return VisitList(node.Params);
        }

        public override VisitResult Visit(ExprModTypeSpec node)
        {
            return Visit(node.Expr);
        }

        public override VisitResult Visit(SimpleName node) => VisitResult.Continue;
        public override VisitResult Visit(IdentifierName node) => VisitResult.Continue;

        public override VisitResult Visit(GenericName node)
        {
            return VisitList(node.TypeArguments);
        }

        public override VisitResult Visit(QualifiedName node)
        {
            if (Visit(node.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(node.Right);
        }

        public override VisitResult Visit(AttributedExpr node)
        {
            return Visit(node.Expr);
        }

        public override VisitResult Visit(NewInterpolatedStringOpExpr node)
        {
            return Visit(node.Expr);
        }

        public override VisitResult Visit(NewLambdaOpExpr node)
        {
            return Visit(node.Expr);
        }

        public override VisitResult Visit(InterpolatedStringExpr node)
        {
            return VisitList(node.Exprs);
        }

        public override VisitResult Visit(RangeExpr node)
        {
            if (Visit(node.Left) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(node.Right);
        }

        public override VisitResult Visit(DeleteOpExpr node)
        {
            return Visit(node.Expr);
        }

        public override VisitResult Visit(CondOpExpr node)
        {
            if (Visit(node.Expr) == VisitResult.Stop) return VisitResult.Stop;
            if (Visit(node.TrueExpr) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(node.FalseExpr);
        }

        public override VisitResult Visit(NullCondOpExpr node)
        {
            if (Visit(node.Expr) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(node.NullExpr);
        }

        public override VisitResult Visit(UninitializedExpr node) => VisitResult.Continue;

        public override VisitResult Visit(BlockExpr node)
        {
            if (VisitList(node.Statements) == VisitResult.Stop) return VisitResult.Stop;
            return Visit(node.ResultExpr);
        }
    }
}