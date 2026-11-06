using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestTupleIteration
{
	[Test]
	public static void BindingsUseOneAstFieldAndOtherForFormsStillParse()
	{
		let parser = scope BeefParser("""
			class Example
			{
				void Run()
				{
					for (let (key, value) in items) Use(key, value);
					for (var (single) in items) Use(single);
					for (let item in items) Use(item);
					for (var (key, value) = GetPair(); KeepGoing(); Step()) Use(key, value);
					for (items) Use();
				}
			}
			""");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let statements = ((CompoundStmt)((MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0]).Body).Statements;
		let pair = (TupleExpr)((ForeachStmt)statements[0]).Binding;
		Test.Assert(pair.Elements.Count == 2);
		Test.Assert(((IdentifierExpr)pair.Elements[0]).Value == "key");
		Test.Assert(((TupleExpr)((ForeachStmt)statements[1]).Binding).Elements.Count == 1);
		Test.Assert(((IdentifierExpr)((ForeachStmt)statements[2]).Binding).Value == "item");
		Test.Assert(statements[3] is ForStmt);
		Test.Assert(((ForeachStmt)statements[4]).Binding == null);
		let code = root.ToString(.. scope .());
		let roundTrip = scope BeefParser(code);
		roundTrip.BreakOnError = false;
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok, code);
		defer delete formattedRoot;
	}

	[Test]
	public static void TupleBindingElementsMustBeNames()
	{
		String[?] sources = .("class C { void F() { for (let (key + 1, value) in items) Use(); } }", "class C { void F() { for (let (, value) in items) Use(); } }");
		for (let source in sources)
		{
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err);
			Test.Assert(root == null);
		}
	}

	[Test]
	public static void TupleIterationRoundTrips()
	{
		let parser = scope BeefParser("class Example { void Run() { for (let (key, value) in items) Use(key, value); } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("let (key, value)"));
		Test.Assert(code.Contains("in items"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
