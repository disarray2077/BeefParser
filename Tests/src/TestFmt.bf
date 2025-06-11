using System;
using System.Collections;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestFmt
{
	[Test]
	public static void TestFmt()
	{
		List<Statement> list = scope .();

		IdentifierExpr hi = new IdentifierExpr() { Value = "Hi" };
		defer delete hi;

		Test.Assert(hi.ToString(.. scope .()) == "Hi");

		list.Add($"return left = {hi};");

		let code = list[0].ToString(.. scope .());
		Test.Assert(code == "return left = Hi;");

		Release!(list, ContainerReleaseKind.Items);
		GC.Collect(false);
	}

	[Test]
	public static void TestFmt2()
	{
		List<Statement> list = scope .();

		IdentifierExpr left = new IdentifierExpr() { Value = "left" };
		defer delete left;

		IdentifierExpr hi = new IdentifierExpr() { Value = "Hi" };
		defer delete hi;

		list.Add($"return {left} = {hi};");
		
		let code = list[0].ToString(.. scope .());
		Test.Assert(code == "return left = Hi;");

		Release!(list, ContainerReleaseKind.Items);
		GC.Collect(false);
	}
}