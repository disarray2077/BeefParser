using System;
using System.IO;
using BeefParser;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestVisitor
{
	class MyASTVisitor : ASTVisitor
	{
		public int Found = 0;

		public override VisitResult Visit(MethodDecl node)
		{
			if (node.Name == "Main" || node.Name == "GetEnumerator")
				Found += 1;
			return base.Visit(node);
		}

		public override VisitResult Visit(ClassDecl node)
		{
			if (node.Name == "Program")
				Found += 1;
			return base.Visit(node);
		}

		public override VisitResult Visit(NamespaceDecl node)
		{
			if (node.Name.Value == "Test1")
				Found += 1;
			return base.Visit(node);
		}
	};

	[Test]
	public static void TestVisitor()
	{
		String text = scope .();
		Test.Assert(File.ReadAllText("./src/Test1.txt", text, true) case .Ok);

		let parser = scope BeefParser(text);

		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		let visitor = scope MyASTVisitor();
		visitor.Visit(root);

		Test.Assert(visitor.Found == 4);

		GC.Collect(false);
	}
}