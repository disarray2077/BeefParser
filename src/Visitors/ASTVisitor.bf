using System;

namespace BeefParser.AST;

/// Node callbacks without child traversal. Dispatch with node.Accept(visitor).
/// Use ASTWalker for structural traversal.
[GenerateASTVisitors(ASTVisitorGenerator.Sources.Visitor)]
public abstract class ASTVisitor
{
    public virtual VisitResult Visit(ASTNode node) => .Continue;
}

public interface IASTVisitorWithCustomResult
{
    protected typealias TResult = Object;
    public virtual TResult Visit(ASTNode node) => default;
}

[GenerateASTVisitors(ASTVisitorGenerator.Sources.ResultVisitor)]
public abstract class ASTVisitor<TResult> : IASTVisitorWithCustomResult
{
    public TResult Visit(ASTNode node)
    {
        if (node != null)
            return Dispatch(node);
        return default;
    }

    public virtual TResult DefaultVisit(ASTNode node) => default;

    public Object IASTVisitorWithCustomResult.Visit(ASTNode node) => Visit(node);
}
