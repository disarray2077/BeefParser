using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestBoxingSyntax
{
	[Test]
	public static void AllocationBindingsAndOperandsRoundTrip()
	{
		String[?] sources = .("new box *ValuePointer", "scope:mixin box i", "scope box i",
			"new:allocator box i", "scope:: box i", "new:(owner.Allocator) box GetValue()",
			"new box values[index]", "new box (i + 1)");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.ParseTo(let expr) case .Ok, source);
			defer delete expr;
			Test.Assert(expr is BoxOpExpr, source);
			let generated = expr.ToString(.. scope .());
			Test.Assert(generated == source, generated);
			let second = scope BeefParser(generated);
			second.BreakOnError = false;
			Test.Assert(second.ParseTo(let copy) case .Ok, generated);
			defer delete copy;
			Test.Assert(copy is BoxOpExpr);
			Test.Assert(copy.ToString(.. scope .()) == generated);
		}
	}

	[Test]
	public static void BoxingPreservesAllocationAndOperandStructure()
	{
		let parser = scope BeefParser("new box *ValuePointer");
		parser.BreakOnError = false;
		Test.Assert(parser.ParseTo(let expr) case .Ok);
		defer delete expr;
		let boxing = (BoxOpExpr)expr;
		Test.Assert(!boxing.IsScope && !boxing.IsAppend && boxing.Bind == null);
		Test.Assert(boxing.Expr is PointerIndirectionExpr);
		Test.Assert(((IdentifierExpr)((PointerIndirectionExpr)boxing.Expr).Expr).Value == "ValuePointer");

		let scopedParser = scope BeefParser("scope:mixin box i");
		scopedParser.BreakOnError = false;
		Test.Assert(scopedParser.ParseTo(let scoped) case .Ok);
		defer delete scoped;
		let scopedBox = (BoxOpExpr)scoped;
		Test.Assert(scopedBox.IsScope && !scopedBox.IsAppend);
		Test.Assert(scopedBox.Bind.Kind == .Mixin);
		Test.Assert(((IdentifierExpr)scopedBox.Expr).Value == "i");
	}

	[Test]
	public static void BoxingConsumesAnExpressionAndStopsAtArgumentSeparators()
	{
		let parser = scope BeefParser("Call(new box i + 1, scope:mixin box flag ? a : b)");
		parser.BreakOnError = false;
		Test.Assert(parser.ParseTo(let expr) case .Ok);
		defer delete expr;
		let call = (CallOpExpr)expr;
		Test.Assert(call.Params.Count == 2);
		Test.Assert(((BoxOpExpr)call.Params[0]).Expr is BinaryOpExpr);
		Test.Assert(((BoxOpExpr)call.Params[1]).Expr is CondOpExpr);
		let generated = expr.ToString(.. scope .());
		let second = scope BeefParser(generated);
		second.BreakOnError = false;
		Test.Assert(second.ParseTo(let copy) case .Ok, generated);
		defer delete copy;
		Test.Assert(((CallOpExpr)copy).Params.Count == 2);
	}

	class IdentifierWalker : ASTWalker
	{
		public int Count;
		public override VisitResult Visit(IdentifierExpr node)
		{
			Count++;
			return .Continue;
		}
	}

	class RenameIdentifiers : ASTRewriter
	{
		public override ASTNode Visit(IdentifierExpr node)
		{
			if (node.Value == "allocator") node.Value = "replacement";
			if (node.Value == "i") node.Value = "value";
			return node;
		}
	}

	[Test]
	public static void VisitorsReachAllocatorAndBoxedOperand()
	{
		let parser = scope BeefParser("new:allocator box i");
		parser.BreakOnError = false;
		Test.Assert(parser.ParseTo(let expr) case .Ok);
		defer delete expr;
		let walker = scope IdentifierWalker();
		Test.Assert(walker.Walk(expr) == .Continue);
		Test.Assert(walker.Count == 2);
		let rewriter = scope RenameIdentifiers();
		Test.Assert(rewriter.Rewrite(expr) == expr);
		Test.Assert(expr.ToString(.. scope .()) == "new:replacement box value");
	}

	[Test]
	public static void BoxingInStatementsRoundTripsAndMissingOperandsFail()
	{
		let parser = scope BeefParser("class C { Object F() { let value = scope:mixin box i; return new box *ValuePointer; } }");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let second = scope BeefParser(root.ToString(.. scope .()));
		second.BreakOnError = false;
		Test.Assert(second.Parse(let copy) case .Ok);
		defer delete copy;

		String[?] sources = .("class C { void F() { let value = new box; } }",
			"class C { void F() { Call(scope:mixin box); } }",
			"class C { void F() { let value = new box *; } }");
		for (let source in sources)
		{
			let invalid = scope BeefParser(scope String(source));
			invalid.BreakOnError = false;
			Test.Assert(invalid.Parse(let invalidRoot) case .Err, source);
			Test.Assert(invalidRoot == null);
		}
	}
}
