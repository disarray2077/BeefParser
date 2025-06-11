using System;

namespace BeefParser.Tests;

static class TestCodeGen
{
	[Test]
	public static void TestToString()
	{
		let parser = scope BeefParser("namespace X { class Y { static void Z() { MyCall(ref SomethingElse, out Output[0]); } } }");
		parser.Parse(let root);
		defer delete root;

		let code = root.ToString(.. scope .());
		Test.Assert(code ==
			"""
			namespace X
			{
				public class Y
				{
					static void Z()
					{
						MyCall(ref SomethingElse, out Output[0]);
					}
				}
			}\n
			""");

		GC.Collect(false);
	}

	[Test]
	public static void TestToString2()
	{
		let parser = scope BeefParser("namespace X { class Y { static void Z => 0; static void Z() { NOP!(); return; } } }");
		parser.Parse(let root);
		defer delete root;

		let code = root.ToString(.. scope .());
		Test.Assert(code ==
			"""
			namespace X
			{
				public class Y
				{
					static void Z => 0;
					static void Z()
					{
						NOP!();
						return;
					}
				}
			}\n
			""");

		GC.Collect(false);
	}
}