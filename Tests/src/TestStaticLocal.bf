using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestStaticLocal
{
	[Test]
	public static void LocalStorageModifiersSurviveRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Run() { static Wrapper wrappers = .(1, 2); const int count = 2; int local = 0; } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let body = (CompoundStmt)((MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0]).Body;
		Test.Assert(((DeclarationStmt)body.Statements[0]).IsStatic);
		Test.Assert(((DeclarationStmt)body.Statements[1]).IsConst);
		Test.Assert(!((DeclarationStmt)body.Statements[2]).IsStatic);
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("static Wrapper wrappers"));
		Test.Assert(code.Contains("const int count"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
