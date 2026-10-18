using System;
using System.Collections;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestASTSourceDiscovery
{
	[Test]
	public static void DiscoversBlockNamespacesAndNestedTypes()
	{
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		ASTSourceDiscovery.FindClasses("""
			namespace Example.AST
			{
				// class CommentDecoy {}
				class Outer
				{
					struct Container { class Inner {} }
					void Run() { var text = "class StringDecoy {}"; }
				}
				namespace Nested { class Leaf {} }
			}
			namespace Other { class Separate {} }
			""", names);
		Test.Assert(names.Count == 4);
		Test.Assert(names[0] == "Example.AST.Outer");
		Test.Assert(names[1] == "Example.AST.Outer.Container.Inner");
		Test.Assert(names[2] == "Example.AST.Nested.Leaf");
		Test.Assert(names[3] == "Other.Separate");
	}

	[Test]
	public static void DiscoversSharedFileAndFileScopedDeclarations()
	{
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		ASTSourceDiscovery.FindClasses("""
			namespace Example.AST;
			abstract class Base {}
			class First : Base
			{
				void Run<T>() where T : class { }
				class AfterMethod {}
			}
			class Second : Base {}
			namespace Nested { class Third {} }
			""", names);
		Test.Assert(names.Count == 5);
		Test.Assert(names[0] == "Example.AST.Base");
		Test.Assert(names[1] == "Example.AST.First");
		Test.Assert(names[2] == "Example.AST.First.AfterMethod");
		Test.Assert(names[3] == "Example.AST.Second");
		Test.Assert(names[4] == "Example.AST.Nested.Third");
	}
}
