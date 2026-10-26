using System;
using System.Collections;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestGeneratedTraversal
{
	class AllocationCollector : ASTWalker
	{
		public HashSet<StringView> Markers = new .() ~ delete _;
		public bool PruneFunctions;

		public override VisitResult Visit(NewOpExpr node)
		{
			if (node.IsScope && node.Arguments != null && node.Arguments.Count > 0)
				if (let marker = node.Arguments[0] as StrLiteral)
					Test.Assert(Markers.Add(marker.Value));
			return base.Visit(node);
		}

		public override VisitResult Visit(LambdaOpExpr node)
		{
			if (PruneFunctions)
				return .Continue;
			return base.Visit(node);
		}
	}

	class ControlWalker : ASTWalker
	{
		public List<int64> Values = new .() ~ delete _;
		public bool SkipSiblings;
		public bool StopAtTwo;

		public override VisitResult Visit(ExpressionStmt node)
		{
			if (SkipSiblings && (let value = node.Expr as IntLiteral) && value.Value == 2)
				return .SkipAndContinue;
			return base.Visit(node);
		}

		public override VisitResult Visit(IntLiteral node)
		{
			Values.Add(node.Value);
			return StopAtTwo && node.Value == 2 ? .Stop : .Continue;
		}
	}

	class EditingRewriter : ASTRewriter
	{
		public override ASTNode Visit(ExpressionStmt node)
		{
			if ((let literal = node.Expr as IntLiteral) && literal.Value == 2)
			{
				delete node;
				return null;
			}
			return base.Visit(node);
		}

		public override ASTNode Visit(IntLiteral node)
		{
			let replacement = new IntLiteral(node.Value * 10);
			delete node;
			return replacement;
		}

		public override ASTNode Visit(LetExpr node)
		{
			let replacement = new OutExpr() { Expr = node.Expr };
			node.Expr = null;
			delete node;
			return replacement;
		}
	}

	class ResultVisitor : ASTVisitor<ASTNode>
	{
		public override ASTNode Visit(IntLiteral node) => node;
	}

	class IntegerVisitor : ASTVisitor<int64>
	{
		public override int64 Visit(IntLiteral node) => node.Value;
	}

	[Comptime]
	static bool HasVisit(Type visitor, TypeDeclaration node)
	{
		for (let method in visitor.GetMethods(.Instance | .Public | .DeclaredOnly))
			if (method.Name == "Visit" && method.ParamCount == 1 && method.GetParamType(0).TypeId == node.TypeId)
				return true;
		return false;
	}

	[Comptime]
	static bool VerifyVisitorCoverage()
	{
		let root = TypeDeclaration.GetByName("BeefParser.AST.ASTNode").Get();
		int count = 0;
		// Enumeration is safe here: generation has finished before this test compiles.
		// This independently catches AST declarations missed by source discovery.
		for (let declaration in TypeDeclaration.TypeDeclarations)
		{
			if (!declaration.GetFullName(.. scope .()).StartsWith("BeefParser.AST.") ||
				declaration.[Friend]mTypeFlags.HasFlag(.Abstract))
				continue;
			for (var current = declaration.BaseType; current != null; current = current.BaseType)
			{
				if (current.TypeId != root.TypeId)
					continue;
				Runtime.Assert(HasVisit(typeof(ASTVisitor), declaration), scope $"ASTVisitor misses {declaration}.");
				Runtime.Assert(HasVisit(typeof(ASTVisitor<int64>), declaration), scope $"ASTVisitor<int64> misses {declaration}.");
				Runtime.Assert(HasVisit(typeof(ASTWalker), declaration), scope $"ASTWalker misses {declaration}.");
				Runtime.Assert(HasVisit(typeof(ASTRewriter), declaration), scope $"ASTRewriter misses {declaration}.");
				count++;
				break;
			}
		}
		return count > 0;
	}

	[Test]
	public static void CoversEveryConcreteASTDeclaration()
	{
		const bool complete = VerifyVisitorCoverage();
		Test.Assert(complete);
	}

	static ExpressionStmt Number(int64 value) => new .() { Expr = new IntLiteral(value) };

	static CompoundStmt ControlTree()
	{
		let inner = new CompoundStmt();
		inner.Statements.Add(Number(2));
		inner.Statements.Add(Number(3));
		let root = new CompoundStmt();
		root.Statements.Add(Number(1));
		root.Statements.Add(inner);
		root.Statements.Add(Number(4));
		return root;
	}

	[Test]
	public static void FindsAllocationsAcrossTheWholeTree()
	{
		let parser = scope BeefParser("""
			[Marker(scope Tag("typeAttribute"))]
			class Example<T> : Base<decltype(scope Tag("baseType"))>
				where T : decltype(scope Tag("constraint"))
			{
				Tag field = scope Tag("fieldInitializer");
				[Marker(scope Tag("methodAttribute"))]
				void Run([Marker(scope Tag("parameterAttribute"))] Tag parameter = scope Tag("parameterDefault"))
				{
					var local = scope Tag("initializer");
					Consume(scope Tag("argument"));
					if (Check(scope Tag("ifCondition"))) Consume(scope Tag("then"));
					for (var i = scope Tag("forInit"); Check(scope Tag("forCondition")); Step(scope Tag("forIncrement")))
						Consume(scope Tag("forBody"));
					for (let item in scope Tag("foreachSource")) Consume(scope Tag("foreachBody"));
					while (Check(scope Tag("whileCondition"))) Consume(scope Tag("whileBody"));
					switch (scope Tag("switch"))
					{
					case Match(scope Tag("caseLabel")) when Check(scope Tag("guard")):
						Consume(scope Tag("caseBody"));
					default:
						Consume(scope Tag("defaultBody"));
					}
					defer { Consume(scope Tag("defer")); }
					using (var resource = scope Tag("using")) {}
					YieldReturn!(scope Tag("yield"));
					var holder = new Holder() { Field = scope Tag("objectInitializer") };
					var array = scope Tag[GetSize(scope Tag("arraySize"))];
					var text = scope $"value {scope Tag("interpolation")}";
					var callback = scope () => scope Tag("lambdaBody");
					var conditional = flag ? scope Tag("trueArm") : scope Tag("falseArm");
				}
			}
			""");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		StringView[?] expected = .("typeAttribute", "baseType", "constraint", "fieldInitializer",
			"methodAttribute", "parameterAttribute", "parameterDefault", "initializer", "argument",
			"ifCondition", "then", "forInit", "forCondition", "forIncrement", "forBody",
			"foreachSource", "foreachBody", "whileCondition", "whileBody", "switch", "caseLabel",
			"guard", "caseBody", "defaultBody", "defer", "using", "yield", "objectInitializer",
			"arraySize", "interpolation", "lambdaBody", "trueArm", "falseArm");
		let collector = scope AllocationCollector();
		Test.Assert(collector.Walk(root) == .Continue);
		Test.Assert(collector.Markers.Count == expected.Count);
		for (let marker in expected)
			Test.Assert(collector.Markers.Contains(marker), scope $"Missing allocation '{marker}'");

		let before = root.ToString(.. scope .());
		let rewriter = scope ASTRewriter();
		Test.Assert(rewriter.Rewrite(root) == root);
		Test.Assert(root.ToString(.. scope .()) == before);
		let after = scope AllocationCollector();
		after.Walk(root);
		Test.Assert(after.Markers.Count == expected.Count);
		for (let marker in expected)
			Test.Assert(after.Markers.Contains(marker));
	}

	[Test]
	public static void PrunesFunctionBodiesWithoutSkippingSiblings()
	{
		let parser = scope BeefParser("class Example { void Run() { var f = scope () => scope Tag(\"body\"); Consume(scope Tag(\"after\")); } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let collector = scope AllocationCollector() { PruneFunctions = true };
		Test.Assert(collector.Walk(root) == .Continue);
		Test.Assert(collector.Markers.Count == 1);
		Test.Assert(collector.Markers.Contains("after"));
	}

	[Test]
	public static void StopsTraversalAndSkipsRemainingSiblings()
	{
		let root = ControlTree();
		defer delete root;
		let stopping = scope ControlWalker() { StopAtTwo = true };
		Test.Assert(stopping.Walk(root) == .Stop);
		Test.Assert(stopping.Values.Count == 2);
		Test.Assert(stopping.Values[0] == 1 && stopping.Values[1] == 2);
		let skipping = scope ControlWalker() { SkipSiblings = true };
		Test.Assert(skipping.Walk(root) == .Continue);
		Test.Assert(skipping.Values.Count == 2);
		Test.Assert(skipping.Values[0] == 1 && skipping.Values[1] == 4);
	}

	[Test]
	public static void ReplacesAndRemovesNodesWhilePreservingNullSlots()
	{
		let root = new CompoundStmt();
		defer delete root;
		root.Statements.Add(Number(1));
		root.Statements.Add(null);
		root.Statements.Add(Number(2));
		root.Statements.Add(new ExpressionStmt() { Expr = new LetExpr() { Expr = new IdentifierExpr("kept") } });
		let rewriter = scope EditingRewriter();
		Test.Assert(rewriter.Rewrite(root) == root);
		Test.Assert(root.Statements.Count == 3);
		Test.Assert(((IntLiteral)((ExpressionStmt)root.Statements[0]).Expr).Value == 10);
		Test.Assert(root.Statements[1] == null);
		let replacement = (OutExpr)((ExpressionStmt)root.Statements[2]).Expr;
		Test.Assert(((IdentifierExpr)replacement.Expr).Value == "kept");

		let arrayType = new ArrayTypeSpec() { Element = new IdentifierName() { Identifier = "int" }, Dimensions = 2 };
		defer delete arrayType;
		arrayType.Sizes.Add(null);
		arrayType.Sizes.Add(new IntLiteral(3));
		rewriter.Rewrite(arrayType);
		Test.Assert(arrayType.Sizes.Count == 2 && arrayType.Sizes[0] == null);
		Test.Assert(((IntLiteral)arrayType.Sizes[1]).Value == 30);
	}

	[Test]
	public static void DispatchesNodesHeldThroughAbstractTypes()
	{
		Expression expression = new IntLiteral(7);
		defer { delete expression; }
		let visitor = scope ResultVisitor();
		Test.Assert(visitor.Visit(expression) == expression);
		let integerVisitor = scope IntegerVisitor();
		Test.Assert(integerVisitor.Visit(expression) == 7);
		Test.Assert(integerVisitor.Visit((ASTNode)null) == 0);
		let rewriter = scope EditingRewriter();
		expression = (Expression)rewriter.Visit(expression);
		Test.Assert(((IntLiteral)expression).Value == 70);
	}
}
