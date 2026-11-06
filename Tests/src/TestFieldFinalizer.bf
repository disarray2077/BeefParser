using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestFieldFinalizer
{
	[Test]
	public static void FinalizerStatementsTerminateFields()
	{
		let parser = scope BeefParser("""
			class Example
			{
				Object sentinel ~ { Close(); }
				Object state ~ { Close(); };
				Object items ~ for (let item in _) item.Dispose();
				int Value => 1;
				Object other ~ delete _;
				void Run() {}
			}
			""");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let example = (ClassDecl)root.Declarations[0];
		Test.Assert(example.Declarations.Count == 6);
		Test.Assert(((FieldDecl)example.Declarations[0]).Declaration.Variables[0].Finalizer is CompoundStmt);
		Test.Assert(((FieldDecl)example.Declarations[2]).Declaration.Variables[0].Finalizer is ForeachStmt);
		let code = root.ToString(.. scope .());
		Test.Assert(!code.Contains(";;"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
		Test.Assert(((ClassDecl)formattedRoot.Declarations[0]).Declarations.Count == 6);
	}
}
