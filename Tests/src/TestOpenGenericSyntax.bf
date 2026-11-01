using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestOpenGenericSyntax
{
	[Test]
	public static void TypeOfUnboundGenericsPreservesArity()
	{
		String[?] sources = .("typeof(Span<>)", "typeof(Dictionary<,>)", "typeof(Tuple<,,>)");
		for (int i = 0; i < sources.Count; i++)
		{
			let parser = scope BeefParser(sources[i]);
			parser.BreakOnError = false;
			Test.Assert(parser.ParseTo(let expr) case .Ok, sources[i]);
			defer delete expr;
			let name = (GenericName)((TypeOfOpExpr)expr).TypeSpec;
			Test.Assert(name.IsUnbound);
			Test.Assert(name.TypeArguments.Count == i + 1);
			for (let argument in name.TypeArguments)
				Test.Assert(argument == null);
			Test.Assert(expr.ToString(.. scope .()) == sources[i]);
			let second = scope BeefParser(expr.ToString(.. scope .()));
			second.BreakOnError = false;
			Test.Assert(second.ParseTo(let copy) case .Ok);
			defer delete copy;
			Test.Assert(((GenericName)((TypeOfOpExpr)copy).TypeSpec).TypeArguments.Count == i + 1);
		}
	}

	[Test]
	public static void QualifiedAndNestedUnboundGenericsRoundTrip()
	{
		String[?] sources = .("typeof(System.Span<>)", "typeof(Outer<>.Inner<,>)", "typeof(Wrapper<Span<>>)", "typeof(Span<>).Size");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.ParseTo(let expr) case .Ok, source);
			defer delete expr;
			Test.Assert(expr.ToString(.. scope .()) == source);
		}
	}

	[Test]
	public static void UnboundTypesParticipateInTypeLookahead()
	{
		let parser = scope BeefParser("class C { void F() { Span<> value; } }");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let second = scope BeefParser(root.ToString(.. scope .()));
		second.BreakOnError = false;
		Test.Assert(second.Parse(let copy) case .Ok);
		defer delete copy;
	}

	[Test]
	public static void RejectsMixedOrIncompleteGenericArguments()
	{
		String[?] sources = .("typeof(Span<)", "typeof(Pair<,int>)", "typeof(Pair<int,>)", "typeof(Pair<int,,>)");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.ParseTo(let expr) case .Err, source);
			delete expr;
		}
	}
}
