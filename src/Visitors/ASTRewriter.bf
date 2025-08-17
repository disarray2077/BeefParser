using System;
using System.Diagnostics;
using System.Collections;

namespace BeefParser.AST
{
    public class ASTRewriter : ASTVisitor<ASTNode>
    {
        public virtual ASTNode Rewrite(ASTNode node)
        {
            return Visit(node);
        }

        public void VisitList<T>(List<T> list) where T : ASTNode
        {
            if (list == null) return;
            for (var child in ref list)
            {
                child = (T)Visit(child);
				if (child == null)
					@child.Remove();
            }
        }

        public void VisitDictionary<T>(Dictionary<StringView, T> dict) where T : ASTNode
        {
            if (dict == null) return;
			let copy = scope List<(StringView key, T value)>(dict.GetEnumerator());
            for (let (key, value) in copy)
            {
                var newNode = (T)Visit(value);
				if (newNode == null)
					@key.Remove();
				else if (newNode != value)
					dict[key] = newNode;
            }
        }

        public override ASTNode Visit(CompilationUnit compilationUnit)
        {
            VisitList(compilationUnit.Usings);
            VisitList(compilationUnit.Declarations);
            return compilationUnit;
        }

        public override ASTNode Visit(NamespaceDecl nsDecl)
        {
            VisitList(nsDecl.Declarations);
            return nsDecl;
        }

        public override ASTNode Visit(UsingDirective usingDecl) => usingDecl;

        public override ASTNode Visit(TypeAliasDecl typeAliasDecl)
        {
            typeAliasDecl.TypeSpec = (TypeSpec)Visit(typeAliasDecl.TypeSpec);
            return typeAliasDecl;
        }

        public override ASTNode Visit(FieldDecl fieldDecl)
        {
            fieldDecl.Declaration = (VariableDecl)Visit(fieldDecl.Declaration);
            return fieldDecl;
        }

        public override ASTNode Visit(PropertyDecl propertyDecl)
        {
            propertyDecl.Specification = (TypeSpec)Visit(propertyDecl.Specification);
            propertyDecl.ExplicitInterfaceName = (Name)Visit(propertyDecl.ExplicitInterfaceName);
            VisitList(propertyDecl.Accessors);
            return propertyDecl;
        }

        public override ASTNode Visit(IndexPropertyDecl indexerDecl)
        {
            indexerDecl.Specification = (TypeSpec)Visit(indexerDecl.Specification);
            indexerDecl.ExplicitInterfaceName = (Name)Visit(indexerDecl.ExplicitInterfaceName);
            VisitList(indexerDecl.FormalParameters);
            VisitList(indexerDecl.Accessors);
            return indexerDecl;
        }

        public override ASTNode Visit(VariableDecl varDecl)
        {
            varDecl.Specification = (TypeSpec)Visit(varDecl.Specification);
            VisitList(varDecl.Variables);
            return varDecl;
        }

        public override ASTNode Visit(ClassDecl classDecl)
        {
            VisitList(classDecl.Declarations);
            return classDecl;
        }

        public override ASTNode Visit(StructDecl structDecl)
        {
            VisitList(structDecl.Declarations);
            return structDecl;
        }

        public override ASTNode Visit(EnumDecl enumDecl)
        {
			if (enumDecl.IsSimpleEnum)
            	VisitDictionary(enumDecl.SimpleDeclarations);
			else
            	VisitList(enumDecl.Declarations);
            return enumDecl;
        }

        public override ASTNode Visit(DelegateDecl delDecl)
        {
            delDecl.Specification = (TypeSpec)Visit(delDecl.Specification);
            VisitList(delDecl.FormalParameters);
            return delDecl;
        }

        public override ASTNode Visit(MixinDecl mixinDecl)
        {
            VisitList(mixinDecl.FormalParameters);
            VisitList(mixinDecl.Statements);
			mixinDecl.ReturnExpr = (Expression)Visit(mixinDecl.ReturnExpr);
            return mixinDecl;
        }

        public override ASTNode Visit(MethodDecl methodDecl)
        {
            methodDecl.Specification = (TypeSpec)Visit(methodDecl.Specification);
            VisitList(methodDecl.FormalParameters);
            methodDecl.CompoundStmt = (CompoundStmt)Visit(methodDecl.CompoundStmt);
            return methodDecl;
        }

        public override ASTNode Visit(NullLiteral nullConstExpr) => nullConstExpr;
        public override ASTNode Visit(BoolLiteral boolConstExpr) => boolConstExpr;
        public override ASTNode Visit(IntLiteral numConstExpr) => numConstExpr;
        public override ASTNode Visit(RealLiteral numConstExpr) => numConstExpr;
        public override ASTNode Visit(StrLiteral strConstExpr) => strConstExpr;
        public override ASTNode Visit(CharLiteral chrConstExpr) => chrConstExpr;

        public override ASTNode Visit(AttributedStmt node)
        {
            node.Statement = (Statement)Visit(node.Statement);
            return node;
        }

        public override ASTNode Visit(CompoundStmt compStmt)
        {
            VisitList(compStmt.Statements);
            return compStmt;
        }

        public override ASTNode Visit(DeferStmt deferStmt)
        {
            deferStmt.Body = (Statement)Visit(deferStmt.Body);
            return deferStmt;
        }

        public override ASTNode Visit(DeclarationStmt declStmt)
        {
            declStmt.Declaration = (VariableDecl)Visit(declStmt.Declaration);
            return declStmt;
        }

        public override ASTNode Visit(UsingStmt usingStmt)
        {
            usingStmt.Decl = (VariableDecl)Visit(usingStmt.Decl);
            usingStmt.Expr = (Expression)Visit(usingStmt.Expr);
            usingStmt.Body = (Statement)Visit(usingStmt.Body);
            return usingStmt;
        }

        public override ASTNode Visit(IfStmt ifStmt)
        {
            ifStmt.Condition = (Expression)Visit(ifStmt.Condition);
            ifStmt.ThenStatement = (Statement)Visit(ifStmt.ThenStatement);
            ifStmt.ElseStatement = (Statement)Visit(ifStmt.ElseStatement);
            return ifStmt;
        }

        public override ASTNode Visit(ForStmt forStmt)
        {
            VisitList(forStmt.Initializers);
            forStmt.Declaration = (VariableDecl)Visit(forStmt.Declaration);
            forStmt.Condition = (Expression)Visit(forStmt.Condition);
            VisitList(forStmt.Incrementors);
            forStmt.Body = (Statement)Visit(forStmt.Body);
            return forStmt;
        }

        public override ASTNode Visit(ForeachStmt foreachStmt)
        {
            foreachStmt.TargetType = (TypeSpec)Visit(foreachStmt.TargetType);
            foreachStmt.SourceExpr = (Expression)Visit(foreachStmt.SourceExpr);
            foreachStmt.Body = (Statement)Visit(foreachStmt.Body);
            return foreachStmt;
        }

        public override ASTNode Visit(WhileStmt whileStmt)
        {
            whileStmt.Condition = (Expression)Visit(whileStmt.Condition);
            whileStmt.Body = (Statement)Visit(whileStmt.Body);
            return whileStmt;
        }

        public override ASTNode Visit(RepeatStmt repeatStmt)
        {
            repeatStmt.Body = (Statement)Visit(repeatStmt.Body);
            repeatStmt.Condition = (Expression)Visit(repeatStmt.Condition);
            return repeatStmt;
        }

        public override ASTNode Visit(DoStmt doStmt)
        {
            doStmt.Body = (Statement)Visit(doStmt.Body);
            return doStmt;
        }

        public override ASTNode Visit(SwitchStmt switchStmt)
        {
            switchStmt.Expr = (Expression)Visit(switchStmt.Expr);
            VisitList(switchStmt.Sections);
            switchStmt.DefaultSection = (SwitchSection)Visit(switchStmt.DefaultSection);
            return switchStmt;
        }

        public override ASTNode Visit(LabeledStmt labeledStmt)
        {
            labeledStmt.Statement = (Statement)Visit(labeledStmt.Statement);
            return labeledStmt;
        }

        public override ASTNode Visit(IdentifierExpr identExpr) => identExpr;

        public override ASTNode Visit(BinaryOpExpr binOpExpr)
        {
            binOpExpr.Left = (Expression)Visit(binOpExpr.Left);
            binOpExpr.Right = (Expression)Visit(binOpExpr.Right);
            return binOpExpr;
        }

        public override ASTNode Visit(BitwiseOpExpr bitOpExpr)
        {
            bitOpExpr.Left = (Expression)Visit(bitOpExpr.Left);
            bitOpExpr.Right = (Expression)Visit(bitOpExpr.Right);
            return bitOpExpr;
        }

        public override ASTNode Visit(LogicalOpExpr logicalOpExpr)
        {
            logicalOpExpr.Left = (Expression)Visit(logicalOpExpr.Left);
            logicalOpExpr.Right = (Expression)Visit(logicalOpExpr.Right);
            return logicalOpExpr;
        }

        public override ASTNode Visit(UnaryOpExpr unaryOpExpr)
        {
            unaryOpExpr.Right = (Expression)Visit(unaryOpExpr.Right);
            return unaryOpExpr;
        }

        public override ASTNode Visit(PostfixOpExpr postfixOpExpr)
        {
            postfixOpExpr.Left = (Expression)Visit(postfixOpExpr.Left);
            return postfixOpExpr;
        }

        public override ASTNode Visit(ComparisonOpExpr compOpExpr)
        {
            compOpExpr.Left = (Expression)Visit(compOpExpr.Left);
            compOpExpr.Right = (Expression)Visit(compOpExpr.Right);
            return compOpExpr;
        }

        public override ASTNode Visit(MemberExpr memberExpr)
        {
            memberExpr.Left = (Expression)Visit(memberExpr.Left);
            memberExpr.Right = (Expression)Visit(memberExpr.Right);
            return memberExpr;
        }

        public override ASTNode Visit(CascadeMemberExpr cascadeExpr)
        {
            cascadeExpr.Left = (Expression)Visit(cascadeExpr.Left);
            cascadeExpr.Right = (Expression)Visit(cascadeExpr.Right);
            return cascadeExpr;
        }

        public override ASTNode Visit(AliasedNamespaceMemberExpr aliasedExpr)
        {
            aliasedExpr.Alias = (IdentifierExpr)Visit(aliasedExpr.Alias);
            aliasedExpr.Right = (Expression)Visit(aliasedExpr.Right);
            return aliasedExpr;
        }

        public override ASTNode Visit(MixinMemberExpr memberExpr)
        {
            memberExpr.Expr = (Expression)Visit(memberExpr.Expr);
            return memberExpr;
        }

        public override ASTNode Visit(IndexOpExpr indexOpExpr)
        {
            indexOpExpr.Left = (Expression)Visit(indexOpExpr.Left);
            VisitList(indexOpExpr.Indexes);
            return indexOpExpr;
        }

        public override ASTNode Visit(CallOpExpr callOpExpr)
        {
            callOpExpr.Expr = (Expression)Visit(callOpExpr.Expr);
            VisitList(callOpExpr.Params);
            return callOpExpr;
        }

        public override ASTNode Visit(TypeOfOpExpr typeOfOpExpr)
        {
            typeOfOpExpr.TypeSpec = (TypeSpec)Visit(typeOfOpExpr.TypeSpec);
            return typeOfOpExpr;
        }

        public override ASTNode Visit(SizeOfOpExpr sizeOfOpExpr)
        {
            sizeOfOpExpr.TypeSpec = (TypeSpec)Visit(sizeOfOpExpr.TypeSpec);
            return sizeOfOpExpr;
        }

        public override ASTNode Visit(DefaultOpExpr defaultOpExpr)
        {
            defaultOpExpr.TypeSpec = (TypeSpec)Visit(defaultOpExpr.TypeSpec);
            return defaultOpExpr;
        }

        public override ASTNode Visit(NewOpExpr newOpExpr)
        {
            newOpExpr.TypeSpec = (TypeSpec)Visit(newOpExpr.TypeSpec);
            VisitList(newOpExpr.Arguments);
            newOpExpr.Initializer = (InitializerExpr)Visit(newOpExpr.Initializer);
            return newOpExpr;
        }

        public override ASTNode Visit(NewArrayOpExpr newArrayOpExpr)
        {
            newArrayOpExpr.TypeSpec = (ArrayTypeSpec)Visit(newArrayOpExpr.TypeSpec);
            newArrayOpExpr.Initializer = (ArrayInitExpr)Visit(newArrayOpExpr.Initializer);
            return newArrayOpExpr;
        }

        public override ASTNode Visit(NewArrayImplicitOpExpr newArrayImplicitOpExpr)
        {
            newArrayImplicitOpExpr.Initializer = (ArrayInitExpr)Visit(newArrayImplicitOpExpr.Initializer);
            return newArrayImplicitOpExpr;
        }

        public override ASTNode Visit(AssignExpr assignOpExpr)
        {
            assignOpExpr.Left = (Expression)Visit(assignOpExpr.Left);
            assignOpExpr.Right = (Expression)Visit(assignOpExpr.Right);
            return assignOpExpr;
        }

        public override ASTNode Visit(CompoundAssignOpExpr cpdAssignOpExpr)
        {
            cpdAssignOpExpr.Left = (Expression)Visit(cpdAssignOpExpr.Left);
            cpdAssignOpExpr.Right = (Expression)Visit(cpdAssignOpExpr.Right);
            return cpdAssignOpExpr;
        }

        public override ASTNode Visit(ReturnStmt retStmt)
        {
            retStmt.Expr = (Expression)Visit(retStmt.Expr);
            return retStmt;
        }

        public override ASTNode Visit(BreakStmt brkStmt) => brkStmt;
        public override ASTNode Visit(ContinueStmt cntStmt) => cntStmt;

        public override ASTNode Visit(CastExpr castExpr)
        {
            castExpr.TypeSpec = (TypeSpec)Visit(castExpr.TypeSpec);
            castExpr.Expr = (Expression)Visit(castExpr.Expr);
            return castExpr;
        }

        public override ASTNode Visit(RefExpr refExpr)
        {
            refExpr.Expr = (Expression)Visit(refExpr.Expr);
            return refExpr;
        }

        public override ASTNode Visit(OutExpr outExpr)
        {
            outExpr.Expr = (Expression)Visit(outExpr.Expr);
            return outExpr;
        }

        public override ASTNode Visit(VarExpr varExpr)
        {
            varExpr.Expr = (Expression)Visit(varExpr.Expr);
            return varExpr;
        }

        public override ASTNode Visit(LetExpr letExpr)
        {
            letExpr.Expr = (Expression)Visit(letExpr.Expr);
            return letExpr;
        }

        public override ASTNode Visit(PointerIndirectionExpr ptrExpr)
        {
            ptrExpr.Expr = (Expression)Visit(ptrExpr.Expr);
            return ptrExpr;
        }

        public override ASTNode Visit(AddressOfExpr addrExpr)
        {
            addrExpr.Expr = (Expression)Visit(addrExpr.Expr);
            return addrExpr;
        }

        public override ASTNode Visit(GenericMemberExpr genMemberExpr)
        {
            genMemberExpr.Left = (Expression)Visit(genMemberExpr.Left);
            VisitList(genMemberExpr.GenericParameters);
            return genMemberExpr;
        }

        public override ASTNode Visit(ExpressionStmt exprStmt)
        {
            exprStmt.Expr = (Expression)Visit(exprStmt.Expr);
            return exprStmt;
        }

        public override ASTNode Visit(ArrayInitExpr arrayInitExpr)
        {
            VisitList(arrayInitExpr.Values);
            return arrayInitExpr;
        }

        public override ASTNode Visit(ObjectInitExpr objectInitExpr)
        {
            VisitList(objectInitExpr.Initializers);
            return objectInitExpr;
        }

        public override ASTNode Visit(LambdaOpExpr node)
        {
            node.Expr = (Expression)Visit(node.Expr);
            node.Statement = (Statement)Visit(node.Statement);
            return node;
        }

        public override ASTNode Visit(VoidTypeSpec node) => node;
        public override ASTNode Visit(DotTypeSpec node) => node;
        public override ASTNode Visit(VarTypeSpec node) => node;
        public override ASTNode Visit(LetTypeSpec node) => node;

        public override ASTNode Visit(ArrayTypeSpec node)
        {
            node.Element = (TypeSpec)Visit(node.Element);
            VisitList(node.Sizes);
            return node;
        }

        public override ASTNode Visit(NullableTypeSpec node)
        {
            node.Element = (TypeSpec)Visit(node.Element);
            return node;
        }

        public override ASTNode Visit(PointerTypeSpec node)
        {
            node.Element = (TypeSpec)Visit(node.Element);
            return node;
        }

        public override ASTNode Visit(RefTypeSpec node)
        {
            node.Element = (TypeSpec)Visit(node.Element);
            return node;
        }

        public override ASTNode Visit(DelegateTypeSpec node)
        {
            node.ReturnType = (TypeSpec)Visit(node.ReturnType);
            VisitList(node.Params);
            return node;
        }

        public override ASTNode Visit(ExprModTypeSpec node)
        {
            node.Expr = (Expression)Visit(node.Expr);
            return node;
        }

        public override ASTNode Visit(SimpleName node) => node;
        public override ASTNode Visit(IdentifierName node) => node;

        public override ASTNode Visit(GenericName node)
        {
            VisitList(node.TypeArguments);
            return node;
        }

        public override ASTNode Visit(QualifiedName node)
        {
            node.Left = (Name)Visit(node.Left);
            node.Right = (SimpleName)Visit(node.Right);
            return node;
        }

        public override ASTNode Visit(AttributedExpr node)
        {
            node.Expr = (Expression)Visit(node.Expr);
            return node;
        }

        public override ASTNode Visit(NewInterpolatedStringOpExpr node)
        {
            node.Expr = (Expression)Visit(node.Expr);
            return node;
        }

        public override ASTNode Visit(NewLambdaOpExpr node)
        {
            node.Expr = (Expression)Visit(node.Expr);
            return node;
        }

        public override ASTNode Visit(InterpolatedStringExpr node)
        {
            VisitList(node.Exprs);
            return node;
        }

        public override ASTNode Visit(RangeExpr node)
        {
            node.Left = (Expression)Visit(node.Left);
            node.Right = (Expression)Visit(node.Right);
            return node;
        }

        public override ASTNode Visit(DeleteOpExpr node)
        {
            node.Expr = (Expression)Visit(node.Expr);
            return node;
        }

        public override ASTNode Visit(CondOpExpr node)
        {
            node.Expr = (Expression)Visit(node.Expr);
            node.TrueExpr = (Expression)Visit(node.TrueExpr);
            node.FalseExpr = (Expression)Visit(node.FalseExpr);
            return node;
        }

        public override ASTNode Visit(NullCondOpExpr node)
        {
            node.Expr = (Expression)Visit(node.Expr);
            node.NullExpr = (Expression)Visit(node.NullExpr);
            return node;
        }

        public override ASTNode Visit(UninitializedExpr node) => node;

        public override ASTNode Visit(BlockExpr node)
        {
            VisitList(node.Statements);
            node.ResultExpr = (Expression)Visit(node.ResultExpr);
            return node;
        }
    }
}