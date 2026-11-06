using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestConstructorBlocks
{
	[Test]
	public static void ConstructorBlocksRemainMethods()
	{
		let parser = scope BeefParser("class Example { static this { Work(); } static this() { Work(); } this() {} public this { Work(); } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let example = (ClassDecl)root.Declarations[0];
		let constructor = (MethodDecl)example.Declarations[0];
		Test.Assert(constructor.IsConstructor && constructor.IsConstructorBlock);
		Test.Assert(constructor.Modifiers.HasFlag(.Static));
		Test.Assert(((CompoundStmt)constructor.Body).Statements.Count == 1);
		Test.Assert(!((MethodDecl)example.Declarations[1]).IsConstructorBlock);
		Test.Assert(!((MethodDecl)example.Declarations[2]).IsConstructorBlock);
		let instanceConstructor = (MethodDecl)example.Declarations[3];
		Test.Assert(instanceConstructor.IsConstructor && instanceConstructor.IsConstructorBlock);
		Test.Assert(!instanceConstructor.Modifiers.HasFlag(.Static));
		Test.Assert(instanceConstructor.AccessLevel == .Public);
		Test.Assert(((CompoundStmt)instanceConstructor.Body).Statements.Count == 1);
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("static this\n"));
		Test.Assert(code.Contains("public this\n"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
		let formattedMembers = ((ClassDecl)formattedRoot.Declarations[0]).Declarations;
		Test.Assert(((MethodDecl)formattedMembers[0]).IsConstructorBlock);
		Test.Assert(((MethodDecl)formattedMembers[3]).IsConstructorBlock);
		Test.Assert(!((MethodDecl)formattedMembers[3]).Modifiers.HasFlag(.Static));
	}
}
