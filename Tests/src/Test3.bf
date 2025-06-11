using System;

namespace BeefParser.Tests;

static class Test3
{
	[Test(ShouldFail=true)]
	public static void TestToString2()
	{
		let parser = scope BeefParser("namespace X { static void Z() { MyCall(ref SomethingElse, out Output[0]); } }");
		parser.Parse(let root);
		defer delete root;

		GC.Collect(false);
	}
}