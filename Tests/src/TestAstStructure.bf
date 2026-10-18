using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestAstStructure
{
	class StructureWalker : ASTWalker
	{
		public int TupleElements;
		public int Bindings;
		public int EnumMembers;
		public int Identifiers;

		public override VisitResult Visit(TupleElement node)
		{
			TupleElements++;
			return base.Visit(node);
		}

		public override VisitResult Visit(BindingSpec node)
		{
			Bindings++;
			return base.Visit(node);
		}

		public override VisitResult Visit(EnumMemberDecl node)
		{
			EnumMembers++;
			return base.Visit(node);
		}

		public override VisitResult Visit(IdentifierExpr node)
		{
			Identifiers++;
			return .Continue;
		}
	}

	class StructureRewriter : ASTRewriter
	{
		public int TupleElements;
		public int Bindings;
		public int EnumMembers;

		public override ASTNode Visit(TupleElement node)
		{
			TupleElements++;
			return base.Visit(node);
		}

		public override ASTNode Visit(BindingSpec node)
		{
			Bindings++;
			return base.Visit(node);
		}

		public override ASTNode Visit(EnumMemberDecl node)
		{
			EnumMembers++;
			return base.Visit(node);
		}

		public override ASTNode Visit(IdentifierName node)
		{
			if (node.Identifier == "int")
				node.Identifier = "uint";
			return node;
		}

		public override ASTNode Visit(IdentifierExpr node)
		{
			if (node.Value == "allocator")
				node.Value = "replacement";
			return node;
		}

		public override ASTNode Visit(IntLiteral node)
		{
			node.Value++;
			return node;
		}
	}

	static BindingSpec GetBinding(Expression expr)
	{
		if (let allocation = expr as NewOpExpr) return allocation.Bind;
		if (let allocation = expr as NewArrayOpExpr) return allocation.Bind;
		if (let allocation = expr as NewArrayImplicitOpExpr) return allocation.Bind;
		if (let allocation = expr as NewInterpolatedStringOpExpr) return allocation.Bind;
		if (let allocation = expr as NewLambdaOpExpr) return allocation.Bind;
		Runtime.FatalError("Expected an allocation expression");
	}

	[Test]
	public static void TupleElementsParticipateInTraversal()
	{
		let parser = scope BeefParser("class Example { (int first, (float x, int y) second) Get() => ?; }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let tuple = (TupleTypeSpec)((MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0]).Specification;
		Test.Assert(tuple.Elements[0].Name == "first");
		Test.Assert(tuple.Elements[0].ToString(.. scope .()) == "int first");

		let walker = scope StructureWalker();
		Test.Assert(walker.Walk(tuple) == .Continue);
		Test.Assert(walker.TupleElements == 4);
		let rewriter = scope StructureRewriter();
		Test.Assert(rewriter.Rewrite(tuple) == tuple);
		Test.Assert(rewriter.TupleElements == 4);
		Test.Assert(tuple.ToString(.. scope .()) == "(uint first, (float x, uint y) second)");
		let formattedParser = scope BeefParser(root.ToString(.. scope .()));
		Test.Assert(formattedParser.Parse(let formattedRoot) case .Ok);
		delete formattedRoot;
	}

	[Test]
	public static void EnumMembersPreserveOrderAndOptionalInitializers()
	{
		let parser = scope BeefParser("enum Values { Last = 30, First, Middle = 10 }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let values = (EnumDecl)root.Declarations[0];
		Test.Assert(values.Members.Count == 3);
		Test.Assert(values.Members[0].Name == "Last");
		Test.Assert(values.Members[1].Name == "First");
		Test.Assert(values.Members[1].Initializer == null);
		Test.Assert(values.Members[2].Name == "Middle");

		let walker = scope StructureWalker();
		walker.Walk(root);
		Test.Assert(walker.EnumMembers == 3);
		let rewriter = scope StructureRewriter();
		rewriter.Rewrite(root);
		Test.Assert(rewriter.EnumMembers == 3);
		Test.Assert(((IntLiteral)values.Members[0].Initializer).Value == 31);
		Test.Assert(values.Members[1].Initializer == null);
		Test.Assert(((IntLiteral)values.Members[2].Initializer).Value == 11);

		let formattedParser = scope BeefParser(root.ToString(.. scope .()));
		Test.Assert(formattedParser.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
		let formattedValues = (EnumDecl)formattedRoot.Declarations[0];
		for (int i = 0; i < values.Members.Count; i++)
			Test.Assert(formattedValues.Members[i].ToString(.. scope .()) == values.Members[i].ToString(.. scope .()));
	}

	[Test]
	public static void AllocationBindingsRoundTrip()
	{
		String[?] inputs = .("scope Widget()", "scope:: Widget()", "scope:mixin Widget()",
			"new:allocator Widget()", "new:(GetAllocator()) uint8[count]*",
			"scope $\"value {count}\"", "scope (x) => x", "scope []");
		BindType[?] kinds = .(.Undefined, .RootScope, .Mixin, .Custom, .Custom, .Undefined, .Undefined, .Undefined);
		for (int i = 0; i < inputs.Count; i++)
		{
			let parser = scope BeefParser(inputs[i]);
			Test.Assert(parser.ParseTo(let expr) case .Ok);
			defer delete expr;
			let binding = GetBinding(expr);
			Test.Assert((binding?.Kind ?? .Undefined) == kinds[i]);
			Test.Assert((binding != null) == (kinds[i] != .Undefined));
			if (binding != null)
				Test.Assert((binding.Target != null) == (kinds[i] == .Custom));

			let walker = scope StructureWalker();
			walker.Walk(expr);
			Test.Assert(walker.Bindings == (binding == null ? 0 : 1));
			let rewriter = scope StructureRewriter();
			rewriter.Rewrite(expr);
			Test.Assert(rewriter.Bindings == walker.Bindings);
			if (i == 3)
				Test.Assert(((IdentifierExpr)binding.Target).Value == "replacement");

			let formatted = expr.ToString(.. scope .());
			let formattedParser = scope BeefParser(formatted);
			Test.Assert(formattedParser.ParseTo(let formattedExpr) case .Ok);
			defer delete formattedExpr;
			Test.Assert(formattedExpr.GetType() == expr.GetType());
			Test.Assert(formattedExpr.ToString(.. scope .()) == formatted);
		}
	}

	[Test]
	public static void AllAllocationFormsTraverseCustomBindingTargets()
	{
		Expression[?] expressions = .(new NewOpExpr(), new NewArrayOpExpr(), new NewArrayImplicitOpExpr(),
			new NewInterpolatedStringOpExpr(), new NewLambdaOpExpr());
		for (let expr in expressions)
		{
			defer delete expr;
			let binding = new BindingSpec() { Kind = .Custom, Target = new IdentifierExpr("allocator") };
			if (let allocation = expr as NewOpExpr) allocation.Bind = binding;
			else if (let allocation = expr as NewArrayOpExpr) allocation.Bind = binding;
			else if (let allocation = expr as NewArrayImplicitOpExpr) allocation.Bind = binding;
			else if (let allocation = expr as NewInterpolatedStringOpExpr) allocation.Bind = binding;
			else if (let allocation = expr as NewLambdaOpExpr) allocation.Bind = binding;

			let walker = scope StructureWalker();
			walker.Walk(expr);
			Test.Assert(walker.Bindings == 1 && walker.Identifiers == 1);
			let rewriter = scope StructureRewriter();
			rewriter.Rewrite(expr);
			Test.Assert(rewriter.Bindings == 1);
			Test.Assert(((IdentifierExpr)GetBinding(expr).Target).Value == "replacement");
		}
	}

	[Test]
	public static void DeferBindingsRemainCompatible()
	{
		let parser = scope BeefParser("class Example { void Run() { defer {} defer:: {} defer:mixin {} } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let body = (CompoundStmt)((MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0]).CompoundStmt;
		Test.Assert(((DeferStmt)body.Statements[0]).Bind == null);
		Test.Assert(((DeferStmt)body.Statements[1]).Bind.Kind == .RootScope);
		Test.Assert(((DeferStmt)body.Statements[2]).Bind.Kind == .Mixin);
		let walker = scope StructureWalker();
		walker.Walk(body);
		Test.Assert(walker.Bindings == 2);
		let rewriter = scope StructureRewriter();
		rewriter.Rewrite(body);
		Test.Assert(rewriter.Bindings == 2);
		let formattedParser = scope BeefParser(root.ToString(.. scope .()));
		Test.Assert(formattedParser.Parse(let formattedRoot) case .Ok);
		delete formattedRoot;
	}
}
