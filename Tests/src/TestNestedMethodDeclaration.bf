using System;
using System.Collections;
using BeefParser;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestNestedMethodDeclaration
{
	[Test]
	public static void ParsesMethodDeclarationsInsideMethods()
	{
		let parser = scope BeefParser("class Example { public void Outer() { int Local(int value) { return value; } Local(1); this.ToString(); } }");

		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		let example = (ClassDecl)root.Declarations[0];
		let outer = (MethodDecl)example.Declarations[0];
		let body = (CompoundStmt)outer.CompoundStmt;
		Test.Assert(body.Statements.Count == 3);

		let localMethod = (LocalMethodStmt)body.Statements[0];
		Test.Assert(localMethod.MethodDeclaration.Name == "Local");
		Test.Assert(localMethod.MethodDeclaration.FormalParameters.Count == 1);
		Test.Assert(localMethod.MethodDeclaration.CompoundStmt is CompoundStmt);

		Test.Assert(body.Statements[1] is ExpressionStmt);
		Test.Assert(body.Statements[2] is ExpressionStmt);
	}

	[Test]
	public static void ParsesGenericLocalMethodsInStatementLists()
	{
		List<Statement> statements = scope .();
		defer { Release!(statements, ContainerReleaseKind.Items); }

		let parser = scope BeefParser("""
			static T Local<T>(T value) where T : IHashable
			{
				int Inner() { return 1; }
				Inner();
				return value;
			}
			int result = Local<int>(1);
			Local<int>(result);
			""");

		Test.Assert(parser.ParseTo(statements) case .Ok);
		Test.Assert(statements.Count == 3);

		let local = ((LocalMethodStmt)statements[0]).MethodDeclaration;
		Test.Assert(local.Name == "Local");
		Test.Assert(local.Modifiers.HasFlag(.Static));
		Test.Assert(local.GenericParametersNames.Count == 1);
		Test.Assert(local.GenericParametersNames[0] == "T");
		Test.Assert(local.GenericConstraints.Count == 1);

		let localBody = (CompoundStmt)local.CompoundStmt;
		Test.Assert(localBody.Statements.Count == 3);
		Test.Assert(((LocalMethodStmt)localBody.Statements[0]).MethodDeclaration.Name == "Inner");
		Test.Assert(((DeclarationStmt)statements[1]).Declaration != null);
		Test.Assert(statements[2] is ExpressionStmt);
	}

	[Test]
	public static void FormatsLocalMethodsInsideMethodBodies()
	{
		let parser = scope BeefParser("class Example { public void Outer() { int Local(int value) { return value; } Local(1); } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		Test.Assert(root.ToString(.. scope .()) ==
			"""
			public class Example
			{
				public void Outer()
				{
					int Local(int value)
					{
						return value;
					}
					Local(1);
				}
			}\n
			""");
	}
}
