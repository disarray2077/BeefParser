using System;
using System.IO;
using BeefParser;
using BeefParser.AST;

namespace BeefParser.Tests;

static class Test2
{
	[Test]
	public static void Test()
	{
		String text = scope .();
		Test.Assert(File.ReadAllText("./src/Test2.txt", text, true) case .Ok);

		let parser = scope BeefParser(text);

		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		Test.Assert(root.Declarations.Count == 1);

		NamespaceDecl testNamespace = root.Declarations[0] as NamespaceDecl;
		Test.Assert(testNamespace.Name.Value == "Test2");
		Test.Assert(testNamespace.Declarations.Count == 1);

		ClassDecl program = testNamespace.Declarations[0] as ClassDecl;
		Test.Assert(program.Name == "Program");
		Test.Assert(program.Declarations.Count == 1);

		let geMethod = program.Declarations[0] as MethodDecl;
		Test.Assert(geMethod.AccessLevel == .Private);
		Test.Assert(geMethod.Name == "GetEnumerator");
		Test.Assert(geMethod.FormalParameters.Count == 4);

		let compoundStmt = geMethod.CompoundStmt as CompoundStmt;
		Test.Assert(compoundStmt.Statements.Count == 2);
	}
}