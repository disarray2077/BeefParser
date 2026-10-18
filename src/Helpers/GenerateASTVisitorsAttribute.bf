using System;

namespace BeefParser.AST;

/// The attribute argument forces the shared source prepass before visitor TypeInit.
[AttributeUsage(.Class)]
struct GenerateASTVisitorsAttribute : Attribute, IOnTypeInit
{
	private String mSource;

	public this(String source)
	{
		mSource = source;
	}

	[Comptime]
	public void OnTypeInit(Type owner, Self* prev)
	{
		Compiler.EmitTypeBody(owner, mSource);
	}
}
