using System;
using System.IO;
using BeefParser;
using BeefParser.AST;

namespace BeefParser.Tests;

static class Test1
{
	[Test]
	public static void Test()
	{
		String text = scope .();
		Test.Assert(File.ReadAllText("./src/Test1.txt", text, true) case .Ok);

		let parser = scope BeefParser(text);

		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		Test.Assert(root.Declarations.Count == 1);

		NamespaceDecl testNamespace = root.Declarations[0] as NamespaceDecl;
		Test.Assert(testNamespace.Name.Value == "Test1");
		Test.Assert(testNamespace.Declarations.Count == 1);

		ClassDecl program = testNamespace.Declarations[0] as ClassDecl;
		Test.Assert(program.Name == "Program");
		Test.Assert(program.Declarations.Count == 2);

		let mainMethod = program.Declarations[0] as MethodDecl;
		Test.Assert(mainMethod.AccessLevel == .Public);
		Test.Assert(mainMethod.Name == "Main");
		Test.Assert(mainMethod.FormalParameters.Count == 0);

		let geMethod = program.Declarations[1] as MethodDecl;
		Test.Assert(geMethod.AccessLevel == .Private);
		Test.Assert(geMethod.Name == "GetEnumerator");
		Test.Assert(geMethod.FormalParameters.Count == 4);

		(String, String)[?] parameters = .(("Segment", "head"), ("Segment", "tail"), ("int", "headLow"), ("int", "tailHigh"));
		for (let param in geMethod.FormalParameters)
		{
			Test.Assert(param.Specification.ToString(.. scope .()) == parameters[@param.Index].0);
			Test.Assert(param.Name == parameters[@param.Index].1);
		}
	}
}