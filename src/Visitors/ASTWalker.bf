using System;
using System.Collections;

namespace BeefParser.AST;

/// Traverses all structural children, including inherited fields, in declaration order.
/// Override a typed Visit and omit base.Visit to prune that node's subtree.
[GenerateASTVisitors(ASTVisitorGenerator.Sources.Walker)]
public class ASTWalker : ASTVisitor
{
    public new VisitResult Visit(ASTNode node)
    {
        if (node != null)
            return node.Accept(this);
        return .Continue;
    }

    public virtual VisitResult Walk(ASTNode node) => Visit(node);

    public VisitResult VisitList<T>(List<T> list) where T : ASTNode
    {
        if (list == null)
            return .Continue;
        for (let node in list)
        {
            let result = Visit((ASTNode)node);
            if (result != .Continue)
                return result;
        }
        return .Continue;
    }
}
