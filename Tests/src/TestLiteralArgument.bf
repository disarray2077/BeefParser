using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestLiteralArgument
{
	[Test]
	public static void NegativeNumericArgumentsRoundTrip()
	{
		let parser = scope BeefParser("class C { void F() { Get<T, -1>(); Holder<T, -42> value; Holder<T, -1.5> real; Get<T, const -1 + 2>(); } }");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("Get<T, -1>()"));
		Test.Assert(code.Contains("Holder<T, -42>"));
		Test.Assert(code.Contains("Holder<T, -1.5>"));
		let roundTrip = scope BeefParser(code);
		roundTrip.BreakOnError = false;
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok, code);
		defer delete formattedRoot;
	}

	[Test]
	public static void InferredArgumentsDoNotConsumeArbitraryExpressions()
	{
		String[?] sources = .("class C { void F() { Holder<T, -1 + 2> value; } }", "class C { void F() { Holder<T, -true> value; } }", "class C { void F() { Holder<T, -> value; } }");
		for (let source in sources)
		{
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err);
			Test.Assert(root == null);
		}
	}

	[Test]
	public static void LiteralValuesRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Run() { Get<T, 0, false, const Flags.None, const \"Invoke\">(); Holder<T, const (1 + 2)> value; Holder<T, 1> inferred; bool flag = (true); int number = (1) + 2; } }");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok, scope $"Position {parser.ErrorPosition}");
		defer delete root;
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("T, 0, false"));
		Test.Assert(code.Contains("Holder<T, 1>"));
		let roundTrip = scope BeefParser(code);
		roundTrip.BreakOnError = false;
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
