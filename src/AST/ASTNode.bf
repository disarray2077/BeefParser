using System;

namespace BeefParser.AST
{
	public abstract class ASTNode
	{
		public abstract VisitResult Accept(ASTVisitor visitor);
	}
}
