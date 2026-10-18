using System;
using System.Collections;
using System.IO;
using System.Reflection;

namespace BeefParser.AST;

/// Shared comptime prepass. No declaration-wide reflection or generated files are used.
static class ASTVisitorGenerator
{
	public const (String Visitor, String ResultVisitor, String Walker, String Rewriter) Sources = GenerateAll();

	[Comptime]
	private static (String Visitor, String ResultVisitor, String Walker, String Rewriter) GenerateAll()
	{
		let paths = scope List<String>();
		defer { ClearAndDeleteItems!(paths); }
		CollectSourceFiles(scope $"{Compiler.ProjectDir}/src/AST", paths);
		paths.Sort();
		let names = scope List<String>();
		defer { ClearAndDeleteItems!(names); }
		for (let path in paths)
		{
			let source = scope String();
			Runtime.Assert(File.ReadAllText(path, source) case .Ok, scope $"Unable to read AST source '{path}'.");
			ASTSourceDiscovery.FindClasses(source, names);
		}
		names.Sort();
		let root = TypeDeclaration.GetByName("BeefParser.AST.ASTNode").Get();
		let nodes = scope List<TypeDeclaration>();
		StringView previous = default;
		for (let name in names)
		{
			if (name == previous)
				continue;
			previous = name;
			// Inactive conditional declarations and excluded source files have no type.
			if (!(TypeDeclaration.GetByName(name) case .Ok(let declaration)))
				continue;
			if (IsNode(declaration, root) && !declaration.[Friend]mTypeFlags.HasFlag(.Abstract))
				nodes.Add(declaration);
		}
		Runtime.Assert(nodes.Count > 0, "No concrete AST nodes found for visitor generation.");

		let visitor = new String();
		let resultVisitor = new String();
		let walker = new String();
		let rewriter = new String();
		for (let node in nodes)
		{
			// Abstract overloads would capture Expression/Statement calls intended for
			// the ASTNode dispatcher. Only concrete types receive Visit overloads.
			visitor.AppendF("public virtual VisitResult Visit({0} node) => Visit(({1})node);\n", node, node.BaseType);
			resultVisitor.AppendF("public virtual TResult Visit({0} node) => DefaultVisit(node);\n", node);
			walker.AppendF("public override VisitResult Visit({0} node)\n{{\nif (node == null) return .Continue;\n", node);
			rewriter.AppendF("public override ASTNode Visit({0} node)\n{{\nif (node == null) return null;\n", node);
			EmitChildren(node.ResolvedType, root, walker, rewriter);
			walker.Append("return .Continue;\n}\n");
			rewriter.Append("return node;\n}\n");
		}
		resultVisitor.Append("private TResult Dispatch(ASTNode node)\n{\nswitch ((int)node.GetType().TypeId)\n{\n");
		for (let node in nodes)
			resultVisitor.AppendF("case {0}: return Visit(({1})node);\n", (int)node.TypeId, node);
		resultVisitor.Append("default: return DefaultVisit(node);\n}\n}\n");
		return (visitor, resultVisitor, walker, rewriter);
	}

	[Comptime]
	private static void CollectSourceFiles(StringView directory, List<String> paths)
	{
		// Comptime directory enumeration and reads register compiler rebuild watches.
		for (let entry in Directory.EnumerateFiles(directory, "*.bf"))
			paths.Add(entry.GetFilePath(.. new String()));
		for (let entry in Directory.EnumerateDirectories(directory))
			CollectSourceFiles(entry.GetFilePath(.. scope .()), paths);
	}

	[Comptime]
	private static bool IsNode(TypeDeclaration declaration, TypeDeclaration root)
	{
		for (var current = declaration; current != null; current = current.BaseType)
			if (current.TypeId == root.TypeId)
				return true;
		return false;
	}

	[Comptime]
	private static bool ContainsNode(Type type, TypeDeclaration root)
	{
		if (IsNode(type.TypeDeclaration, root))
			return true;
		if (type.IsArray || type.IsPointer)
			return ContainsNode(type.UnderlyingType, root);
		if (let generic = type as SpecializedGenericType)
			for (int i = 0; i < generic.GenericParamCount; i++)
				if (ContainsNode(generic.GetGenericArg(i), root))
					return true;
		return false;
	}

	[Comptime]
	private static void EmitChildren(Type type, TypeDeclaration root, String walker, String rewriter)
	{
		if (type.BaseType != null && IsNode(type.BaseType.TypeDeclaration, root))
			EmitChildren(type.BaseType, root, walker, rewriter);
		for (let field in type.GetFields(.Instance | .Public | .NonPublic | .DeclaredOnly))
		{
			if (!field.IsInstanceField)
				continue;
			let childType = field.FieldType;
			bool isNode = IsNode(childType.TypeDeclaration, root);
			bool isList = false;
			if (let generic = childType as SpecializedGenericType)
				isList = generic.UnspecializedType == typeof(List<>) && IsNode(generic.GetGenericArg(0).TypeDeclaration, root);
			if (!isNode && !isList)
			{
				if (ContainsNode(childType, root))
					Runtime.FatalError(scope $"Unsupported AST child container '{type}.{field.Name}' of type '{childType}'.");
				continue;
			}
			let name = field.GetSourceName(.. scope .());
			// Select the declaring type so a derived field cannot hide a base child.
			let access = scope $"(({type})node).[Friend]{name}";
			if (isList)
			{
				walker.AppendF("switch (VisitList({0}))\n", access);
				rewriter.AppendF("VisitList({0});\n", access);
			}
			else
			{
				walker.AppendF("switch (Visit((ASTNode){0}))\n", access);
				rewriter.AppendF("{0} = RewriteChild({0});\n", access);
			}
			walker.Append("{ case .Continue: break; case .SkipAndContinue: return .Continue; case .Stop: return .Stop; }\n");
		}
	}
}
