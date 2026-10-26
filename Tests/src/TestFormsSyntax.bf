using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestFormsSyntax
{
	static void RoundTrip(String source)
	{
		let parser = scope BeefParser(source);
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok, source);
		defer delete root;
		let generated = root.ToString(.. scope .());
		let second = scope BeefParser(generated);
		second.BreakOnError = false;
		Test.Assert(second.Parse(let copy) case .Ok, generated);
		defer delete copy;
		Test.Assert(copy.ToString(.. scope .()) == generated, generated);
	}

	[Test]
	public static void EscapedSurrogateCodeUnitsRoundTrip()
	{
		String[?] sources = .(@"'\u{D800}'", @"'\u{DFFF}'");
		uint32[?] values = .(0xD800, 0xDFFF);
		for (int i = 0; i < sources.Count; i++)
		{
			let parser = scope BeefParser(sources[i]);
			parser.BreakOnError = false;
			Test.Assert(parser.ParseTo(let expr) case .Ok);
			defer delete expr;
			Test.Assert((uint32)((CharLiteral)expr).Value == values[i]);
			Test.Assert(expr.ToString(.. scope .()) == sources[i]);
		}
	}

	[Test]
	public static void DigitSeparatedRealsAndDecltypeAreOwned()
	{
		let parser = scope BeefParser("1'000'000.0");
		parser.BreakOnError = false;
		Test.Assert(parser.ParseTo(let expr) case .Ok);
		defer delete expr;
		Test.Assert(((RealLiteral)expr).Value == 1000000.0);
		RoundTrip("class C { void F() { Call(sizeof(decltype(value))); } }");
	}

}
