using System;
using BeefParser.AST;

using internal BeefParser;

namespace BeefParser
{
	internal enum ContextScopeType
	{
		Undefined,
		MemberInit,
		Assignment,
		BlockExpression
	}

	internal class ParserContext
	{
		public CompilationUnit CompilationUnit;
		public NamespaceDecl Namespace;
		public BaseTypeDecl Type;
		public MethodDecl Method;
		public MixinDecl Mixin;
		public ContextScopeType ScopeType;
	}
}
