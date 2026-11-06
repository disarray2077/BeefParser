using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestTypeOperators
{
	class OperandWalker : ASTWalker
	{
		public int Targets;
		public int Types;

		public override VisitResult Visit(IdentifierExpr node)
		{
			Targets++;
			return base.Visit(node);
		}

		public override VisitResult Visit(IdentifierName node)
		{
			Types++;
			return base.Visit(node);
		}
	}

	[Test]
	public static void AsReturnsWhileIsContinues()
	{
		let parser = scope BeefParser("""
			class Example
			{
				bool Check() => value is Foo is bool;
				object Cast() => value is Foo as Bar;
				bool Bound() => value as Foo != null;
				object Recast() => (value as Foo) as Bar;
				bool Grouped() => (value as Foo) is Bar;
				void Generic() { Use<const value is int>(); Use<const value as Foo>(); }
			}
			""");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let members = ((ClassDecl)root.Declarations[0]).Declarations;
		Test.Assert(((CheckTypeExpr)((MethodDecl)members[0]).Body).Target is CheckTypeExpr);
		Test.Assert(((DynamicCastExpr)((MethodDecl)members[1]).Body).Target is CheckTypeExpr);
		Test.Assert(((ComparisonOpExpr)((MethodDecl)members[2]).Body).Left is DynamicCastExpr);
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("(value as Foo) as Bar"));
		Test.Assert(code.Contains("(value as Foo) is Bar"));
		let roundTrip = scope BeefParser(code);
		roundTrip.BreakOnError = false;
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok, code);
		defer delete formattedRoot;
	}

	[Test]
	public static void DedicatedNodesOwnExpressionAndTypeOperands()
	{
		String[?] sources = .("value as StringView?", "value as int*", "value is Span<int>", "value is int*");
		for (let source in sources)
		{
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.ParseTo(let expr) case .Ok);
			defer delete expr;
			if (source.Contains(" as "))
			{
				let cast = expr as DynamicCastExpr;
				Test.Assert(cast != null);
				Test.Assert(cast.Target is IdentifierExpr);
				Test.Assert(cast.TypeSpec != null);
			}
			else
			{
				let check = expr as CheckTypeExpr;
				Test.Assert(check != null);
				Test.Assert(check.Target is IdentifierExpr);
				Test.Assert(check.TypeSpec != null);
			}
			let walker = scope OperandWalker();
			walker.Visit(expr);
			Test.Assert(walker.Targets == 1 && walker.Types == 1);
			Test.Assert(expr.ToString(.. scope .()) == source);
		}
	}

	[Test]
	public static void InvalidTypeOperatorOperandsAreRejected()
	{
		String[?] sources = .("class C { void F() { bool b = value is; } }", "class C { void F() { var v = value as; } }", "class C { void F() { var v = value as A as B; } }", "class C { void F() { bool v = value as A is B; } }");
		for (let source in sources)
		{
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err);
			Test.Assert(root == null);
		}
	}

	[Test]
	public static void NullableCastTypesRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Run() { if (var sv = value as StringView?) Use(sv); var pointer = value as int*; bool matches = value is Span<int*>; if (value is int* && matches) Use(value); } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("as StringView?"));
		Test.Assert(code.Contains("as int*"));
		Test.Assert(code.Contains("is Span<int*>"));
		Test.Assert(code.Contains("is int*"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
