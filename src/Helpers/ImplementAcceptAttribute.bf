using System;
using System.Diagnostics;

namespace BeefParser.AST;

struct ImplementAcceptAttribute : Attribute, IOnTypeInit
{
	[Comptime]
	public void OnTypeInit(Type type, Self* prev)
	{
		Compiler.EmitTypeBody(type,
			"""
			public override VisitResult Accept(ASTVisitor visitor)
			{
				return visitor.Visit(this);
			}\n
			""");
		Compiler.EmitTypeBody(type,
			"""
			public override System.Object AcceptWithCustomResult(IASTVisitorWithCustomResult visitor)
			{
				return visitor.Visit(this);
			}
			""");
	}
}