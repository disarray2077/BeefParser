using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestFromEndIndex
{
	[Test]
	public static void FromEndIndicesPreserveUnaryAndBinaryOperators()
	{
		let parser = scope BeefParser("class Example { int Last() => values[^1] ^ values[^(count + 1)]; }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let method = (MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		let binary = (BitwiseOpExpr)method.Body;
		Test.Assert(binary.Operation == .BitwiseXor);
		Test.Assert(((UnaryOpExpr)((IndexOpExpr)binary.Left).Indexes[0]).Operation == .BitwiseXor);
		let code = root.ToString(.. scope .());
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
