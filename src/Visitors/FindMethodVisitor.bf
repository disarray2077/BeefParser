using System;

namespace BeefParser.AST;

class FindMethodVisitor : ASTVisitor
{
	private StringView mMethodName;
	public MethodDecl FoundMethod { get; private set; }

	public this(StringView methodName)
	{
		mMethodName = methodName;
	}

	public override VisitResult Visit(MethodDecl methodDecl)
	{
		if (methodDecl.Name == mMethodName)
		{
			FoundMethod = methodDecl;
			return .Stop;
		}
		return .Continue;
	}
}