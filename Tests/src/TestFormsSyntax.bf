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
	public static void UnaryConstructsBeforeTernariesRoundTrip()
	{
		String[?] expressions = .(
			"typeof(T) == typeof(void) ? 0 : 1",
			"0 == sizeof(int32) ? 1 : 0",
			"default(bool) ? 1 : 0",
			"typeof(int32).Size == sizeof(int32) ? 1 : 0"
		);
		for (let expression in expressions)
		{
			let source = scope String("class C { int F<T>() { const int32 results = ");
			source.Append(expression);
			source.Append("; return results; } }");
			RoundTrip(source);
		}
	}

	[Test]
	public static void MalformedTernariesReturnErrorsWithoutCrashing()
	{
		String[?] expressions = .("typeof(void) ? ;", "sizeof(int32) ? 1;", "default(bool) ? 1 : ;");
		for (let expression in expressions)
		{
			let source = scope String("class C { void F() { let value = ");
			source.Append(expression);
			source.Append(" } }");
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err, source);
			Test.Assert(root == null);
		}
	}

	[Test]
	public static void DeclarationFormsRoundTrip()
	{
		String[?] sources = .(
			"namespace N; static { internal static int Size(this StringView text) => text.Length; private static mixin Release(var values) { for (let value in values) delete value; } }",
			"class C { public function int Callback(int value); private delegate void() callback; public delegate void() Action { get; set; } }",
			"class C { public bool AutoCheck { get; set; } = true; public int Start { get; set; } = .Manual; }",
			"extension Event<T> { public implicit void operator+=(T value) mut { Add(value); } public implicit void operator-=(T value) mut { Remove(value); } }"
		);
		for (let source in sources)
			RoundTrip(scope String(source));
	}

	[Test]
	public static void AllocationsCapturesAndArgumentsRoundTrip()
	{
		String[?] expressions = .("Call(value: false)", "Call(option: flag ? 1 : 2, count: 3)", "new => OnClick", "scope => owner.Callback", "new:ScopedAlloc! .[size]", "scope [&] () => value = callback()", "scope [=] () => Tick()", "scope [&value, other] () => value = other", "scope [value] () => Tick(value)", "scope [] () => Tick()");
		for (let source in expressions)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.ParseTo(let expr) case .Ok, source);
			defer delete expr;
			let generated = expr.ToString(.. scope .());
			let second = scope BeefParser(generated);
			second.BreakOnError = false;
			Test.Assert(second.ParseTo(let copy) case .Ok, generated);
			defer delete copy;
			Test.Assert(copy.ToString(.. scope .()) == generated, generated);
		}
	}

	[Test]
	public static void NewNodesParticipateInTraversal()
	{
		let parser = scope BeefParser("Call(value: new C())");
		parser.BreakOnError = false;
		Test.Assert(parser.ParseTo(let expr) case .Ok);
		defer delete expr;
		let call = (CallOpExpr)expr;
		let named = (NamedArgumentExpr)call.Params[0];
		Test.Assert(named.Name == "value");
		Test.Assert(named.Value is NewOpExpr);
		let walker = scope AllocationWalker();
		Test.Assert(walker.Walk(expr) == .Continue);
		Test.Assert(walker.Count == 1);
	}

	[Test]
	public static void NestedCapturedLambdasKeepIndependentParameters()
	{
		let parser = scope BeefParser("scope [&] (value) => scope [value] (other) => value + other");
		parser.BreakOnError = false;
		Test.Assert(parser.ParseTo(let expr) case .Ok);
		defer delete expr;
		let outer = (LambdaOpExpr)((NewLambdaOpExpr)expr).Expr;
		let inner = (LambdaOpExpr)((NewLambdaOpExpr)outer.Expr).Expr;
		Test.Assert(outer.Captures[0] == "&");
		Test.Assert(outer.FormalParameters[0] == "value");
		Test.Assert(inner.Captures[0] == "value");
		Test.Assert(inner.FormalParameters[0] == "other");
	}

	class AllocationWalker : ASTWalker
	{
		public int Count;

		public override VisitResult Visit(NewOpExpr node)
		{
			Count++;
			return base.Visit(node);
		}
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

	[Test]
	public static void GenericConstructorsRetainTheirTypeParameters()
	{
		let parser = scope BeefParser("class C { public this<T>(T value) { } public T Identity<T>(T value) { return value; } }");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let members = ((ClassDecl)root.Declarations[0]).Declarations;
		let constructor = (MethodDecl)members[0];
		Test.Assert(constructor.IsConstructor);
		Test.Assert(constructor.GenericParametersNames[0] == "T");
		let method = (MethodDecl)members[1];
		Test.Assert(!method.IsConstructor);
		Test.Assert(method.GenericParametersNames[0] == "T");
	}

	[Test]
	public static void RejectsIncompleteForms()
	{
		String[?] sources = .("class C { bool P { get; set; } = ; }", "class C { void F() { Call(value:); } }", "static { void F( }", "class C { void F() { let f = new =>; } }", "class C { void F() { let f = scope [&] () =>; } }");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err, source);
			Test.Assert(root == null);
		}
	}
}
