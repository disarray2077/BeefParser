using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestOpaqueStruct
{
	[Test]
	public static void OpaqueDeclarationsRoundTrip()
	{
		let parser = scope BeefParser("struct Opaque; struct Concrete {} struct Primary : this(int X);");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		Test.Assert(((StructDecl)root.Declarations[0]).IsOpaque);
		Test.Assert(!((StructDecl)root.Declarations[1]).IsOpaque);
		Test.Assert(!((StructDecl)root.Declarations[2]).IsOpaque);
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("struct Opaque;"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
