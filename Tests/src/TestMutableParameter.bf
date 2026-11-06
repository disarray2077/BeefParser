using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestMutableParameter
{
	[Test]
	public static void MutableCallableParametersRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Run(function void(mut T this, int) setter) {} }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("function void(mut T this, int) setter"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
