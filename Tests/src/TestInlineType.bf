using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestInlineType
{
	class InlineDeclarationWalker : ASTWalker
	{
		public int Cases;

		public override VisitResult Visit(EnumCaseDecl node)
		{
			Cases++;
			return base.Visit(node);
		}
	}

	[Test]
	public static void InlineEnumsReuseCaseAndMemberDeclarations()
	{
		let parser = scope BeefParser("""
			class Example
			{
				private void Test(enum { case A; } a) {}
				void Payload(enum { case B(int value); int Value => 1; } b) {}
			}
			""");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let methods = ((ClassDecl)root.Declarations[0]).Declarations;
		let first = (EnumDecl)((InlineTypeSpec)((MethodDecl)methods[0]).FormalParameters[0].Specification).Declaration;
		Test.Assert(!first.IsSimpleEnum);
		Test.Assert(((EnumCaseDecl)first.Declarations[0]).Items[0].Name == "A");
		let second = (EnumDecl)((InlineTypeSpec)((MethodDecl)methods[1]).FormalParameters[0].Specification).Declaration;
		Test.Assert(((EnumCaseDecl)second.Declarations[0]).Items[0].Parameters.Count == 1);
		Test.Assert(second.Declarations[1] is PropertyDecl);
		let walker = scope InlineDeclarationWalker();
		walker.Visit(root);
		Test.Assert(walker.Cases == 2);
		let code = root.ToString(.. scope .());
		let roundTrip = scope BeefParser(code);
		roundTrip.BreakOnError = false;
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok, code);
		defer delete formattedRoot;
	}

	[Test]
	public static void InlineDeclarationsWorkInTypeLookaheadAndOtherTypeKinds()
	{
		String[?] sources = .(
			"class C { void F(struct { public int Value; } item) {} }",
			"class C { void F(class { public int Value; } item) {} }",
			"class C { void F() { enum { case A; } local; } }",
			"class C { void F(enum : uint8 { A = 1, B } value) {} }",
			"class C { void F() { Call(([Friend]Type.Value)); } }"
		);
		for (let source in sources)
		{
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Ok, source);
			defer delete root;
			let code = root.ToString(.. scope .());
			let roundTrip = scope BeefParser(code);
			roundTrip.BreakOnError = false;
			Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok, code);
			defer delete formattedRoot;
		}
	}

	[Test]
	public static void IncompleteInlineDeclarationsReleasePartialTrees()
	{
		String[?] sources = .("class C { void F(enum { case ; } value) {} }", "class C { void F(enum { A = } value) {} }");
		for (let source in sources)
		{
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err);
			Test.Assert(root == null);
		}
	}

	[Test]
	public static void InlineEnumParametersRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Run(enum { Inline, Other = 2 } name) {} }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let code = root.ToString(.. scope .());
		let method = (MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		let declaration = (EnumDecl)((InlineTypeSpec)method.FormalParameters[0].Specification).Declaration;
		Test.Assert(declaration.IsSimpleEnum);
		Test.Assert(declaration.Members.Count == 2);
		Test.Assert(declaration.Members[1].Name == "Other");
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}

	[Test]
	public static void InlineFieldsUseOrdinaryDeclaratorsAndInitializers()
	{
		let parser = scope BeefParser("""
			struct Example
			{
				[Union] public struct { public int x; public float y; } first, second;
				struct { public int Value; } initialized = default;
				struct Named {}
				Named named;
				enum { case A; } choice;
			}
			""");
		parser.BreakOnError = false;
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let members = ((StructDecl)root.Declarations[0]).Declarations;
		Test.Assert(members.Count == 5);
		let shared = ((FieldDecl)members[0]).Declaration;
		Test.Assert(shared.Specification is InlineTypeSpec);
		Test.Assert(shared.Variables.Count == 2);
		Test.Assert(shared.Variables[0].Name == "first" && shared.Variables[1].Name == "second");
		Test.Assert(((FieldDecl)members[1]).Declaration.Variables[0].Initializer is DefaultOpExpr);
		Test.Assert(((StructDecl)members[2]).Name == "Named");
		Test.Assert(((FieldDecl)members[3]).Declaration.Specification is IdentifierName);
		Test.Assert(((InlineTypeSpec)((FieldDecl)members[4]).Declaration.Specification).Declaration is EnumDecl);
		let code = root.ToString(.. scope .());
		let roundTrip = scope BeefParser(code);
		roundTrip.BreakOnError = false;
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok, code);
		defer delete formattedRoot;
		Test.Assert(((StructDecl)formattedRoot.Declarations[0]).Declarations.Count == 5);
	}

	[Test]
	public static void AnonymousStructFieldsRoundTrip()
	{
		let parser = scope BeefParser("struct Example { [Union] public struct { public int x; public float y; } data; int other; }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let code = root.ToString(.. scope .());
		let field = (FieldDecl)((StructDecl)root.Declarations[0]).Declarations[0];
		Test.Assert(field.AccessLevel == .Public);
		Test.Assert(field.Declaration.Variables[0].Name == "data");
		let inlineType = (InlineTypeSpec)field.Declaration.Specification;
		Test.Assert(inlineType.Declaration is StructDecl);
		Test.Assert(inlineType.Declaration.Attributes.Count == 1);
		Test.Assert(inlineType.Declaration.Attributes[0].TypeSpec.ToString(.. scope .()) == "Union");
		Test.Assert(field.Attributes.IsEmpty);
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
		let formattedField = (FieldDecl)((StructDecl)formattedRoot.Declarations[0]).Declarations[0];
		Test.Assert(formattedField.AccessLevel == .Public);
		Test.Assert(formattedField.Declaration.Variables[0].Name == "data");
		let formattedType = (InlineTypeSpec)formattedField.Declaration.Specification;
		Test.Assert(formattedType.Declaration.Attributes.Count == 1);
		Test.Assert(formattedType.Declaration.Attributes[0].TypeSpec.ToString(.. scope .()) == "Union");
	}
}
