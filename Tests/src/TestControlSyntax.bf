using System;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestControlSyntax
{
	[Test]
	public static void PrimaryStructConstructorsRoundTrip()
	{
		String[?] sources = .("struct AnchorInfo : this(int32 Left, int32 Top, int32 Right, int32 Bottom) {}", "struct Empty : this() {}", "struct Pair : this(int X, int Y), IPair {}", "struct Compact : this(int X, int Y);", "struct EmptyCompact : this();");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Ok);
			defer delete root;
			let declaration = (StructDecl)root.Declarations[0];
			Test.Assert(declaration.HasPrimaryConstructor);
			let generated = root.ToString(.. scope .());
			let second = scope BeefParser(generated);
			second.BreakOnError = false;
			Test.Assert(second.Parse(let copy) case .Ok, generated);
			defer delete copy;
			let roundTrip = (StructDecl)copy.Declarations[0];
			Test.Assert(roundTrip.HasPrimaryConstructor);
			Test.Assert(roundTrip.PrimaryConstructorParameters.Count == declaration.PrimaryConstructorParameters.Count);
			Test.Assert(roundTrip.Inheritance.Count == declaration.Inheritance.Count);
			for (let parameter in declaration.PrimaryConstructorParameters)
				Test.Assert(parameter.Name == roundTrip.PrimaryConstructorParameters[@parameter.Index].Name);
		}
	}

	[Test]
	public static void PropertyFinalizersRoundTrip()
	{
		String[?] sources = .("class C { public Object Value { get; set; } ~ delete _; }", "class C { public Object Value { get; set; } ~ { delete _; }; }", "class C { public Object this[int index] { get => null; } ~ delete _; }");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Ok);
			defer delete root;
			Test.Assert(((BasePropertyDecl)((ClassDecl)root.Declarations[0]).Declarations[0]).Finalizer != null);
			let generated = root.ToString(.. scope .());
			let second = scope BeefParser(generated);
			second.BreakOnError = false;
			Test.Assert(second.Parse(let copy) case .Ok, generated);
			defer delete copy;
			Test.Assert(((BasePropertyDecl)((ClassDecl)copy.Declarations[0]).Declarations[0]).Finalizer != null);
		}
	}

	[Test]
	public static void RejectsIncompletePrimaryConstructorsAndFinalizers()
	{
		String[?] sources = .("struct S : this {}", "struct S : this(int X,) {}", "struct S : this(int X {}", "class C { Object Value { get; set; } ~ ; }", "class C { Object Value { get; set; } ~ delete _ }");
		for (let source in sources)
		{
			let parser = scope BeefParser(scope String(source));
			parser.BreakOnError = false;
			Test.Assert(parser.Parse(let root) case .Err, source);
			Test.Assert(root == null);
		}
	}
}
