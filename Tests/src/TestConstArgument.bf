using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestConstArgument
{
	[Test]
	public static void FullExpressionsStopAtTheirGenericDelimiter()
	{
		let parser = scope BeefParser("""
			class Example
			{
				void Run()
				{
					Get<const 1 + 2 * 3, const Flags.A | Flags.B>();
					Get<const flag ? 1 : 2>();
					Holder<const 1 + 2> value;
					Holder<Inner<const 1 + 2>> nested;
					Get<const Select(a > b, x >> 1), const values[a > b ? 1 : 0]>();
					Get<const (a > b), const (x >> 1)>();
					Get<const Select(Inner<const 1 + 2>(), a > b)>();
					Get<const $"{a > b}">();
					Get<const () => 1>();
					Get<const () => { return a > b; }>();
					Get<const new Holder() { Flag = a > b }>();
					Get<const new:(Select(a > b)) Holder()>();
					Get<const new int[Select(a > b)](1)>();
					bool result = Get<const 1 + 2>() > 0;
				}
				int Shift(int value) => value >> 1;
			}
			""");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let body = (CompoundStmt)((MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0]).Body;
		let firstCall = (CallOpExpr)((ExpressionStmt)body.Statements[0]).Expr;
		let arguments = ((GenericMemberExpr)firstCall.Expr).GenericParameters;
		Test.Assert(((ConstArgumentTypeSpec)arguments[0]).Value is BinaryOpExpr);
		Test.Assert(((ConstArgumentTypeSpec)arguments[1]).Value is BitwiseOpExpr);
		let code = root.ToString(.. scope .());
		let roundTrip = scope BeefParser(code);
		roundTrip.BreakOnError = false;
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok, code);
		defer delete formattedRoot;
	}

	[Test]
	public static void MissingConstantOperandsAreRejected()
	{
		String[?] sources = .("class C { void F() { Get<const>(); } }", "class C { void F() { Get<const 1 +>(); } }", "class C { void F() { Get<const Flags.A |>(); } }");
		for (let source in sources)
		{
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err);
			Test.Assert(root == null);
		}
	}

	[Test]
	public static void ConstantValuesRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Run() { Get<T, const 0, const false, const Flags.None, const \"Invoke\">(); Holder<T, const (1 + 2)> value; } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("const 0"));
		Test.Assert(code.Contains("const false"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
