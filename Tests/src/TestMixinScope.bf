using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestMixinScope
{
	[Test]
	public static void LabeledMixinCallsRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Run() { Pop!:mixin<String>(lua, -1); Make!:depth1(value); } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("!:mixin<String>"));
		Test.Assert(code.Contains("!:depth1"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
