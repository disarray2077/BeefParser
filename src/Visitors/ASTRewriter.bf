using System;
using System.Collections;

namespace BeefParser.AST;

/// Rewrites children in place and preserves nodes by default.
/// An override returning a replacement or null owns disposal of the old node;
/// detach any reused children before deleting it. Null removes existing list entries,
/// while null placeholders already in a list are preserved.
[GenerateASTVisitors(ASTVisitorGenerator.Sources.Rewriter)]
public class ASTRewriter : ASTVisitor<ASTNode>
{
    public virtual ASTNode Rewrite(ASTNode node) => Visit(node);

    public override ASTNode DefaultVisit(ASTNode node) => node;

    protected T RewriteChild<T>(T node) where T : ASTNode
    {
        let rewritten = Visit((ASTNode)node);
        Runtime.Assert(rewritten == null || rewritten is T,
            "An AST rewrite returned a node incompatible with its parent field.");
        return (T)rewritten;
    }

    public void VisitList<T>(List<T> list) where T : ASTNode
    {
        if (list == null)
            return;
        for (var child in ref list)
        {
            if (child == null)
                continue;
            child = RewriteChild(child);
            if (child == null)
                @child.Remove();
        }
    }
}
