using System;
using System.IO;
using BeefParser;
using BeefParser.AST;

namespace BeefParser.Tests;

static class MetaTest
{
	[Test]
	public static void Test()
	{
		for (int i = 0; i < 1000; i++)
		{
			String text = scope .();

			const String[?] filePaths = .(
				@"d:\BeefLang\Repository\Beef\BeefLibs\corlib\src\Collections\List.bf",
				"../src/Visitors/CodeGenVisitor.bf",
				"../src/BeefParser.bf"
			);

			Test.Assert(File.ReadAllText(filePaths[i % filePaths.Count], text, true) case .Ok);
	
			let parser = scope BeefParser(text);
	
			Test.Assert(parser.Parse(let root) case .Ok);
			defer delete root;
		}

		GC.Collect(false);
	}
}