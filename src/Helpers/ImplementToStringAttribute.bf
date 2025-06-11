using System;
using System.Diagnostics;

namespace BeefParser.AST;

struct ImplementToStringAttribute : Attribute, IOnTypeInit
{
	[Comptime]
	public void OnTypeInit(Type type, Self* prev)
	{
		Compiler.EmitTypeBody(type,
			"""
			public override void ToString(System.String outString)
			{
				let codeGen = scope CodeGenVisitor(outString);
				codeGen.Visit(this);
			}
			""");
	}
}