using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestWin32Syntax
{
	[Test]
	public static void AppendFieldModifierRoundTrips()
	{
		let source = scope String("class Backend { private append Dictionary<void*, Object> mControls = .(); }");
		let parser = scope BeefParser(source);
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let field = (FieldDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		Test.Assert(field.Modifiers.HasFlag(.Append));
		Test.Assert(field.AccessLevel == .Private);
		let generated = root.ToString(.. scope .());
		Test.Assert(generated.Contains("private append Dictionary<void*, Object> mControls = .();"));
		let second = scope BeefParser(generated);
		second.BreakOnError = false;
		Test.Assert(second.Parse(let copy) case .Ok);
		defer delete copy;
		Test.Assert(((FieldDecl)((ClassDecl)copy.Declarations[0]).Declarations[0]).Modifiers.HasFlag(.Append));
	}

	[Test]
	public static void MethodBindingsRoundTripAsDistinctExpressions()
	{
		String[?] sources = .("=> WindowProc", "=> backend.ChildWindowProc", "=> Backend.Callback<int>");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.ParseTo(let expression) case .Ok);
			defer delete expression;
			Test.Assert(expression is MethodBindingExpr);
			let text = expression.ToString(.. scope .());
			Test.Assert(text == source);
			let second = scope BeefParser(text);
			second.BreakOnError = false;
			Test.Assert(second.ParseTo(let copy) case .Ok);
			defer delete copy;
			Test.Assert(copy is MethodBindingExpr);
		}
	}

	class BindingWalker : ASTWalker
	{
		public int Bindings;
		public int Identifiers;

		public override VisitResult Visit(MethodBindingExpr node)
		{
			Bindings++;
			return base.Visit(node);
		}

		public override VisitResult Visit(IdentifierExpr node)
		{
			Identifiers++;
			return base.Visit(node);
		}
	}

	[Test]
	public static void BindingTargetsParticipateInTraversal()
	{
		let parser = scope BeefParser("Register(=> backend.WindowProc)");
		parser.BreakOnError = false;
		Test.Assert(parser.ParseTo(let expression) case .Ok);
		defer delete expression;
		let call = (CallOpExpr)expression;
		Test.Assert(call.Params[0] is MethodBindingExpr);
		let walker = scope BindingWalker();
		Test.Assert(walker.Walk(expression) == .Continue);
		Test.Assert(walker.Bindings == 1);
		Test.Assert(walker.Identifiers == 3);
	}

	[Test]
	public static void RejectsMissingBindingTargetsAndDuplicateAppend()
	{
		String[?] sources = .("class C { append append Object field; }", "class C { Object value = =>; }", "class C { void F() { Register(=>); } }");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err);
			Test.Assert(root == null);
		}
	}
}
