using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestNullCoalescingAssignment
{
	[Test]
	public static void LexerDistinguishesQuestionMarkOperators()
	{
		let lexer = scope Lexer("??= ?? ?. ? = ?? =");
		TokenType[?] kinds = .(.NullCoarlAssign, .NullCoarl, .NullCond, .QuestionMark, .Assign, .NullCoarl, .Assign, .EOF);
		int[?] positions = .(0, 4, 7, 10, 12, 14, 17, 18);
		for (int i = 0; i < kinds.Count; i++)
		{
			Test.Assert(lexer.GetNextToken() case .Ok(let token));
			Test.Assert(token.Type == kinds[i]);
			Test.Assert(token.Position == positions[i]);
		}
	}

	[Test]
	public static void AssignmentPrecedenceAndAssociativityArePreserved()
	{
		let parser = scope BeefParser("first ??= second ??= fallback ?? other");
		parser.BreakOnError = false;
		Test.Assert(parser.ParseTo(let expr) case .Ok);
		defer delete expr;
		let outer = (CompoundAssignOpExpr)expr;
		Test.Assert(outer.Operation == .NullCoarlAssign);
		Test.Assert(outer.Left.ToString(.. scope .()) == "first");
		let inner = (CompoundAssignOpExpr)outer.Right;
		Test.Assert(inner.Operation == .NullCoarlAssign);
		Test.Assert(inner.Left.ToString(.. scope .()) == "second");
		Test.Assert(inner.Right is NullCondOpExpr);
		Test.Assert(expr.ToString(.. scope .()) == "first ??= second ??= (fallback ?? other)");
	}

	[Test]
	public static void StatementsAndExpressionBodiesRoundTrip()
	{
		String[?] sources = .(
			"class C { void F(Object appearance) { var appearance; appearance ??= control; } }",
			"class C { void F() { owner.Value ??= flag ? First() : Second(); items[index] ??= Create(); } }",
			"class C { void F() => value ??= Create(); Object G() => value ??= fallback; }"
		);
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Ok, source);
			defer delete root;
			let generated = root.ToString(.. scope .());
			Test.Assert(generated.Contains("??="), generated);
			let second = scope BeefParser(generated);
			second.BreakOnError = false;
			Test.Assert(second.Parse(let copy) case .Ok, generated);
			defer delete copy;
			Test.Assert(copy.ToString(.. scope .()) == generated, generated);
		}
	}

	[Test]
	public static void MissingOperandsReturnErrors()
	{
		String[?] sources = .("class C { void F() { value ??=; } }", "class C { void F() { ??= value; } }", "class C { void F() { value ?? = other; } }");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err, source);
			Test.Assert(root == null);
		}
	}
}
