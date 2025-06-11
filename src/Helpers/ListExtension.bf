using System;
using System.Collections;
using BeefParser;
using BeefParser.AST;
using System.Diagnostics;

namespace BeefParser
{
	static
	{
		internal static bool All<T, TPred>(this List<T> list, TPred pred)
			where TPred : delegate bool(T)
		{
			for (let item in list)
				if (!pred(item))
					return false;
			return true;
		}
	
		internal static int Count<T, TComp>(this List<T> list, TComp comparer)
			where TComp : delegate bool(T)
		{
			int count = 0;
			for (let item in list)
			{
				if (comparer(item))
					count++;
			}
			return count;
		}
	}
}

namespace BeefParser.AST
{
	static
	{
		public static Result<void> Add(this List<Statement> list, String code)
		{
			return list.Insert(list.Count, code); 
		}

		public static Result<void> Insert(this List<Statement> list, int index, String code)
		{
			BeefParser parser = scope .(code);
			Try!(parser.ParseTo(list, index));
			return .Ok;
		}

		public static Result<void> Add(this List<Statement> list, String codeFormat, params Span<Object> args)
		{
			//return list.Insert(list.Count, codeFormat, params args);  // TODO: BEEF BUG - Unable to implictly cast ???
			return _insert(list, list.Count, codeFormat, params args);
		}
	
		public static Result<void> Insert(this List<Statement> list, int index, String codeFormat, params Span<Object> args)
		{
			return _insert(list, index, codeFormat, params args);
		}

		[NoShow(true)]
		private static Result<void> _insert(List<Statement> list, int index, String codeFormat, params Span<Object> args)
		{
			var codeFormat;
			if (codeFormat.Contains("{{"))
				codeFormat = scope:: String(codeFormat)..Replace("{{", "{")..Replace("}}", "}");

			String code = scope .();
			StringView[] parts = codeFormat.Split!("{}");

			CodeGenVisitor codeGen = scope .(code);

			for (var arg in ref args)
			{
				if (arg == null)
					continue;

				if (!(arg is ASTNode))
				{
					arg = Literal.MakeLiteral(arg);
					defer:: delete arg;
				}
			}

			for (let part in parts)
			{
				code.Append(part);
				
				if (@part != parts.Count - 1)
					codeGen.Visit((ASTNode)args[@part]);
			}

			BeefParser parser = scope .(code);
			Try!(parser.ParseTo(list, index));
			return .Ok;
		}
	}
}