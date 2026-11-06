using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestGenericConstraints
{
	[Test]
	public static void ConstConstraintSpacingIsPreservedAcrossDeclarationKinds()
	{
		String[?] sources = .(
			"enum E<T, C> where T : struct, IHashable where C : const int { case Empty; }",
			"delegate void Callback<T, C>() where T : struct, IHashable where C : const int;",
			"class C { mixin Run<T, N>() where T : struct, IHashable where N : const int {} }"
		);
		for (let source in sources)
		{
			let parser = scope BeefParser(source);
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Ok);
			defer delete root;
			let code = root.ToString(.. scope .());
			Test.Assert(code.Contains("const int"));
			Test.Assert(code.Contains("struct, IHashable"));
			let roundTrip = scope BeefParser(code);
			roundTrip.BreakOnError = false;
			Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok, code);
			defer delete formattedRoot;
		}
	}

	[Test]
	public static void ConstConstraintsRetainTheirTypes()
	{
		let parser = scope BeefParser("class Example { void Bind<Name, Count>() where Name : const String where Count : const int {} }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let method = (MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		Test.Assert(method.GenericConstraints.Count == 2);
		for (let constraint in method.GenericConstraints)
		{
			Test.Assert(constraint.Constraints.Count == 2);
			Test.Assert(constraint.Constraints[0] is ConstConstraint);
			Test.Assert(constraint.Constraints[1] is TypeConstraint);
		}
		Test.Assert(((TypeConstraint)method.GenericConstraints[0].Constraints[1]).TypeSpec.ToString(.. scope .()) == "String");
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("where Name : const String"));
		Test.Assert(code.Contains("where Count : const int"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
		let formattedMethod = (MethodDecl)((ClassDecl)formattedRoot.Declarations[0]).Declarations[0];
		Test.Assert(formattedMethod.GenericConstraints[0].Constraints[0] is ConstConstraint);
		Test.Assert(((TypeConstraint)formattedMethod.GenericConstraints[1].Constraints[1]).TypeSpec.ToString(.. scope .()) == "int");
	}

	[Test]
	public static void PointerConstraintsRetainTheirKinds()
	{
		let parser = scope BeefParser("class Example { void Bind<T>() where T : var, struct* {} }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let method = (MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		Test.Assert(((StructConstraint)method.GenericConstraints[0].Constraints[1]).IsPointer);
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("where T : var, struct*"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}

	[Test]
	public static void QualifiedTargetsRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Bind<T>() where IsDelegate<T>.Result : Yes {} }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let method = (MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		Test.Assert(method.GenericConstraints[0].TargetType is QualifiedName);
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("where IsDelegate<T>.Result : Yes"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}

	[Test]
	public static void EnumConstraintsRoundTrip()
	{
		let parser = scope BeefParser("class Example { void Bind<T>() where T : enum {} }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;
		let method = (MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		Test.Assert(method.GenericConstraints[0].Constraints[0] is EnumConstraint);
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("where T : enum"));
		let roundTrip = scope BeefParser(code);
		Test.Assert(roundTrip.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
	}
}
