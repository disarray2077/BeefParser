using System;
using System.Collections;

namespace BeefParser.AST;

/// Finds declaration names only. The compiler supplies their actual types and fields.
static class ASTSourceDiscovery
{
	public static void FindClasses(String source, List<String> names)
	{
		let lexer = scope Lexer(source, false);
		var tokens = scope List<Token>();
		Runtime.Assert(lexer.GetAllTokens(ref tokens) case .Ok, "Unable to tokenize AST source for visitor generation.");
		int cursor = 0;
		ScanScope(tokens, ref cursor, "", names);
	}

	private static void ScanScope(List<Token> tokens, ref int cursor, StringView prefix, List<String> names)
	{
		let currentPrefix = scope String(prefix);
		while (cursor < tokens.Count)
		{
			let kind = tokens[cursor++].Type;
			switch (kind)
			{
			case .EOF, .RCurly:
				return;
			case .Namespace:
				let qualified = scope String(currentPrefix);
				if (!qualified.IsEmpty)
					qualified.Append('.');
				while (cursor < tokens.Count && tokens[cursor].Type == .Identifier)
				{
					qualified.Append(tokens[cursor++].AsText());
					if (tokens[cursor].Type != .Dot)
						break;
					qualified.Append('.');
					cursor++;
				}
				if (tokens[cursor].Type == .LCurly)
				{
					cursor++;
					ScanScope(tokens, ref cursor, qualified, names);
				}
				else if (tokens[cursor].Type == .Semi)
				{
					cursor++;
					currentPrefix.Set(qualified);
				}
				else
					Runtime.FatalError("Unsupported namespace declaration in AST source.");
			case .Class, .Struct, .Interface, .Enum:
				if (tokens[cursor].Type != .Identifier)
					continue;
				let qualified = scope String(currentPrefix);
				if (!qualified.IsEmpty)
					qualified.Append('.');
				qualified.Append(tokens[cursor++].AsText());
				if (kind == .Class)
					names.Add(new String(qualified));
				// Ignore braces inside primary-constructor arguments and attributes.
				int parentheses = 0;
				int brackets = 0;
				while (cursor < tokens.Count && tokens[cursor].Type != .EOF)
				{
					let headerKind = tokens[cursor++].Type;
					if (headerKind == .LParen) parentheses++;
					else if (headerKind == .RParen) parentheses--;
					else if (headerKind == .LBracket) brackets++;
					else if (headerKind == .RBracket) brackets--;
					else if (parentheses == 0 && brackets == 0)
					{
						if (headerKind == .LCurly)
						{
							ScanScope(tokens, ref cursor, qualified, names);
							break;
						}
						if (headerKind == .Semi)
							break;
					}
				}
			case .LCurly:
				// Ordinary member bodies cannot contain AST type declarations.
				int depth = 1;
				while (cursor < tokens.Count && depth > 0)
				{
					let bodyKind = tokens[cursor++].Type;
					if (bodyKind == .LCurly) depth++;
					else if (bodyKind == .RCurly) depth--;
				}
			default:
				break;
			}
		}
	}
}
