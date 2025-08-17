using System;
using System.Diagnostics;
using System.Collections;
using BeefParser.AST;

using internal BeefParser;

namespace BeefParser
{
	class BeefParser
	{
		private Lexer _lexer ~ delete _;
		private int _tokenIndex;
		private List<Token> _tokens = new List<Token>() ~ Release!(_);

		private Token _lastToken => _tokens[_tokenIndex - 1];
		private Token _currentToken => _tokens[_tokenIndex];
		private Token _nextToken => _tokens[_tokenIndex + 1];

		private bool _usingAllowed = true;
		private int _lastFailureIndex = -1;
		private bool _errorRaisen = false;
		private ParserContext _context = new ParserContext() ~ delete _;

		public this(String text, bool copyText = false)
		{
		    _lexer = new Lexer(text, copyText);
		}

		public Result<void> Parse(out CompilationUnit root)
		{
			root = new CompilationUnit();

			defer
			{
				// TODO: NOTE: Comptime doesn't support @return smh
				if (!Compiler.IsComptime) [ConstSkip]
				{
					if (!(@return case .Ok))
					{
						delete root;
						root = null;
					}
				}
			}

			_tokenIndex = 0;
			if (_tokens.IsEmpty)
				Try!(readTokens());

			{
				scope TemporaryChange<CompilationUnit>(ref _context.CompilationUnit, root);

				if (declarations(ref root.Declarations, true) case .Err)
				{
					if (!_errorRaisen)
						raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
					return .Err;
				}

				eat!(TokenType.EOF);
			}

			return .Ok;
		}

		public static Result<void> Parse(String code, out CompilationUnit root)
		{
			let parser = scope BeefParser(code);
			return parser.Parse(out root);
		}

		public Result<void> ParseTo(List<Statement> outStatements)
		{
			return ParseTo(outStatements, outStatements.Count);
		}

		public static Result<void> ParseTo(String code, List<Statement> outStatements)
		{
			let parser = scope BeefParser(code);
			return parser.ParseTo(outStatements);
		}

		public Result<void> ParseTo(List<Statement> outStatements, int index)
		{
			_tokenIndex = 0;
			if (_tokens.IsEmpty)
				Try!(readTokens());

			int statementCount = 0;
			while (!tryEat!(TokenType.EOF))
			{
				if (tryEat!(TokenType.Semi))
					continue;

				// We do this to make sure even the errored Statement gets deleted with the parent node.
				outStatements.Insert(index + statementCount, (Statement)null);
				Parse!(statement(ref outStatements[index + statementCount], true));
				statementCount++;
			}

			return .Ok;
		}

		public static Result<void> ParseTo(String code, List<Statement> outStatements, int index)
		{
			let parser = scope BeefParser(code);
			return parser.ParseTo(outStatements, index);
		}

		private Result<void> readTokens()
		{
			_tokens.Clear();
			if (_lexer.GetAllTokens(ref _tokens) case .Err(let invalidChar))
			{
				_raiseError(_lexer.getCurrentPosition());
				return .Err;
			}

			return .Ok;
		}

		private mixin raiseError(int position, String message = "")
		{
			_raiseError(position, message);
			return .Err((.)null);
		}

		private mixin raiseErrorF(int position, String message, Object arg1)
		{
			_raiseError(position, scope String()..AppendF(message, arg1));
			return .Err((.)null);
		}

		private mixin raiseErrorF(int position, String message, Object arg1, Object arg2)
		{
			_raiseError(position, scope String()..AppendF(message, arg1, arg2));
			return .Err((.)null);
		}

		private void printLocation(SourcePosition position)
		{
			String lineStr = scope String();
			lineStr.Append(position.lineText);
			lineStr.Replace('\t', ' ');

			Debug.WriteLine(lineStr);
			Debug.WriteLine("{}^", scope String(' ', position.collumn));
		}

		[Inline]
		private void printLocation()
		{
			_lexer.getSourcePosition(_currentToken.Position, let sourcePosition);
			printLocation(sourcePosition);
		}

		private void _raiseError(int position, String message = "")
		{
			_errorRaisen = true;

			_lexer.getSourcePosition(position, let sourcePosition);
			printLocation(sourcePosition);
		    Debug.WriteLine("{} in line {}:{}", message.IsEmpty ? "Invalid syntax" : message, sourcePosition.line, sourcePosition.collumn);
			Debug.Break();

#if DEBUG
			if (!Compiler.IsComptime)
				GC.Collect(false);
#endif
		}

		private mixin tryEat(TokenType tokenType)
		{
			bool result = _currentToken.Type == tokenType;
				
			if (result)
			{
				_tokenIndex++;
#if DEBUG && VERBOSE
				if (_tokenIndex < _tokens.Count)
				{
					Debug.WriteLine("Current Token: {}", _currentToken.Type);
					if (_currentToken.Type == .EOF)
						NOP!();
	
					printLocation();
				}
#endif
			}

			result
		}

		private mixin eat(TokenType tokenType)
		{
		    if (!tryEat!(tokenType))
			{
				raiseErrorF!(_currentToken.Position,
					"Expected \"{}\" got \"{}\"", tokenType, _currentToken.Type);
			}
		}

		private mixin ensureNull(var x)
		{
			if (x != null)
				Runtime.FatalError(scope $"Variable wasn't null, current value is '{x}'");
			ref x
		}

		private bool isReservedType(TokenType type)
		{
			switch (type)
			{
			case .Void, .Object, .Bool, .Char, .Byte, .SByte, .Short, .UShort, .Int, .UInt, .Long, .ULong, .Float, .Double, .Decimal, .String:
				return true;
			default:
				return false;
			}
		}

		private ParseResult<void> parseArraySizes(ref ArrayTypeSpec arrayType)
		{
			if (tryEat!(TokenType.RBracket))
				return .Ok;

			repeat
			{
				// We do this to make sure even the errored Expression gets deleted with the parent node.
				Expression* expr = arrayType.Sizes.GrowUninitialized(1);
				*expr = null;

				if (!tryEat!(TokenType.Comma))
				{
					Parse!(expression(ref *expr));

					if (!tryEat!(TokenType.Comma) && _currentToken.Type != .RBracket)
						raiseError!(_currentToken.Position, "Expected comma");
				}

				arrayType.Dimensions += 1;
			}
			while (!tryEat!(TokenType.RBracket));

			return .Ok;
		}

		private Result<void> parseGenericParameters(ref List<TypeSpec> types)
		{
			repeat
			{
				if (tryEat!(TokenType.QuestionMark))
				{
					// Is this the best way to handle this case...? idk.
					types.Add(null);
					continue;
				}

				// We do this to make sure even the errored TypeSpec gets deleted with the parent node.
				TypeSpec* spec = types.GrowUninitialized(1);
				*spec = null;
				Parse!(typeSpec(ref *spec));
			}
			while (tryEat!(TokenType.Comma));

			return .Ok;
		}

		private ParseResult<void> parseSimpleName<T>(ref T name) where T : Name
		{
			if (!tryEat!(isReservedType(_currentToken.Type) ? _currentToken.Type : TokenType.Identifier))
				return .NotSuitable;

			let value = _lastToken.AsText();
			if (tryEat!(TokenType.LArrow))
			{
				let genericName = new GenericName()
				{
					Identifier = value
				};
				name = genericName;

				Try!(parseGenericParameters(ref genericName.TypeArguments));
				eat!(TokenType.RArrow);
			}
			else
			{
				name = new IdentifierName()
				{
					Identifier = value
				};
			}

			return .Ok;
		}


		private ParseResult<void> parseName(ref Name name)
		{
		    if (!isReservedType(_currentToken.Type) && _currentToken.Type != TokenType.Identifier)
		        return .NotSuitable;

		    Try!(parseSimpleName(ref name));

		    while (tryEat!(TokenType.Dot))
		    {
				let qualifiedName = new QualifiedName()
		        {
		            Left = name,
		        };
		        name = qualifiedName;
				Try!(parseSimpleName(ref qualifiedName.Right));
		    }

		    return .Ok;
		}

		private ParseResult<void> checkParseSimpleName()
		{
			if (!tryEat!(isReservedType(_currentToken.Type) ? _currentToken.Type : TokenType.Identifier))
				return .NotSuitable;

			if (tryEat!(TokenType.LArrow))
			{
				repeat
				{
					if (!TryParse!(checkTypeSpec()))
						return .NotSuitable;
				}
				while (tryEat!(TokenType.Comma));

				if(!tryEat!(TokenType.RArrow))
					return .NotSuitable;
			}

			return .Ok;
		}

		private ParseResult<void> checkParseName()
		{
		    if (!isReservedType(_currentToken.Type) && _currentToken.Type != TokenType.Identifier)
		        return .NotSuitable;
			
			if (!TryParse!(checkParseSimpleName()))
				return .NotSuitable;

		    while (tryEat!(TokenType.Dot))
		    {
		        if (!TryParse!(checkParseSimpleName()))
					return .NotSuitable;
		    }

		    return .Ok;
		}

		private ParseResult<void> checkTypeSpec()
		{
			tryEat!(TokenType.Ref);

			switch (_currentToken.Type)
			{
			case .Var, .Let, .Dot:
				eat!(_currentToken.Type);
				return .Ok;
			case .Delegate, .Function:
				eat!(_currentToken.Type);
				if (!TryParse!(checkTypeSpec()))
					return .NotSuitable;

				if (tryEat!(TokenType.LParen) && !tryEat!(TokenType.RParen))
				{
					List<ParamDecl> parameters = scope .();
					defer { ClearAndDeleteItems!(parameters); }

					if (parseFormalParameters(ref parameters) case .Err)
						return .NotSuitable;

					eat!(TokenType.RParen);
				}
				return .Ok;
			case .DeclType, .CompType:
				eat!(_currentToken.Type);
				eat!(TokenType.LParen);

				Expression expr = null;
				defer { delete expr; }

				if (!TryParse!(expression(ref expr)))
					return .NotSuitable;
				
				eat!(TokenType.RParen);
				return .Ok;
			case .Void:
			default:
			}

			if (!TryParse!(checkParseName()))
				return .NotSuitable;

			while (true)
			{
				if (tryEat!(TokenType.QuestionMark))
					continue;

				if (tryEat!(TokenType.Mul))
					continue;

				if (tryEat!(TokenType.LBracket))
				{
					if (tryEat!(TokenType.RBracket))
						continue;

					int depth = 1;

					while (depth > 0)
					{
						if (_currentToken.Type == .LBracket)
							depth++;
						else if (_currentToken.Type == .RBracket)
							depth--;
						eat!(_currentToken.Type);
					}

					continue;
				}

				break;
			}

			return .Ok;
		}

		private ParseResult<void> typeSpec(ref TypeSpec spec)
		{
			bool isRef = tryEat!(TokenType.Ref);

			switch (_currentToken.Type)
			{
			case .Var:
				eat!(_currentToken.Type);
				spec = new VarTypeSpec();
				return .Ok;
			case .Let:
				eat!(_currentToken.Type);
				spec = new LetTypeSpec();
				return .Ok;
			case .Dot:
				eat!(_currentToken.Type);
				spec = new DotTypeSpec();
				return .Ok;
			case .Delegate, .Function:
				eat!(_currentToken.Type);

				let delegateType = new DelegateTypeSpec()
				{
					Type = _lastToken.Type
				};
				spec = delegateType;

				Parse!(typeSpec(ref delegateType.ReturnType));

				if (tryEat!(TokenType.LParen) && !tryEat!(TokenType.RParen))
				{
					Try!(parseFormalParameters(ref delegateType.Params));
					eat!(TokenType.RParen);
				}
				return .Ok;
			case .DeclType, .CompType:
				eat!(_currentToken.Type);
				
				let exprModType = new ExprModTypeSpec()
				{
					Type = _lastToken.Type
				};
				spec = exprModType;

				eat!(TokenType.LParen);
				Parse!(expression(ref exprModType.Expr));
				eat!(TokenType.RParen);
				return .Ok;
			case .Void:
				eat!(_currentToken.Type);
				spec = new VoidTypeSpec();
			default:
				Name name = null;
				if (!TryParse!(parseName(ref name)))
					return .NotSuitable;
				spec = name;
			}

			defer::
			{
				// TODO: NOTE: Comptime doesn't support @return smh
				if (!Compiler.IsComptime) [ConstSkip]
				{
					if (!(@return case .Ok))
						DeleteAndNullify!(spec);
				}
			}

			while (true)
			{
				if (tryEat!(TokenType.QuestionMark))
				{
					spec = new NullableTypeSpec() { Element = spec };
					continue;
				}
	
				if (tryEat!(TokenType.Mul))
				{
					spec = new PointerTypeSpec() { Element = spec };
					continue;
				}
	
				if (tryEat!(TokenType.LBracket))
				{
					var arrayType = new ArrayTypeSpec() { Element = spec };
					spec = arrayType;

					if (!TryParse!(parseArraySizes(ref arrayType)))
						return .NotSuitable;

					continue;
				}

				break;
			}

			if (isRef)
				spec = new RefTypeSpec() { Element = spec };

			return .Ok;
		}

		private ParseResult<void> usingDirective()
		{
			if (tryEat!(TokenType.Using))
			{
				if (!_usingAllowed)
					raiseError!(_lastToken.Position, "Using declaration must precede all other declarations");
				
				var type = new UsingDirective();

				if (_context.Namespace != null)
					_context.Namespace.Usings.Add(type);
				else if (_context.CompilationUnit != null)
					_context.CompilationUnit.Usings.Add(type);
				else
					Runtime.FatalError();

				if (tryEat!(TokenType.Internal))
					type.isInternal = true;

				if (tryEat!(TokenType.Static))
					type.isStatic = true;

				Parse!(parseName(ref type.Name));
				eat!(TokenType.Semi);

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> namespaceDecl(ref List<Declaration> decls)
		{
			if (tryEat!(TokenType.Namespace))
			{
				var decl = new NamespaceDecl();
				decls.Add(decl);

				Try!(parseName(ref decl.Name));

				bool fileScoped = tryEat!(TokenType.Semi);

				if (!fileScoped)
					eat!(TokenType.LCurly);

				{
					scope TemporaryChange<NamespaceDecl>(ref _context.Namespace, decl);
	
					Try!(declarations(ref decl.Declarations, true));

					if (!fileScoped)
						eat!(TokenType.RCurly);
				}

				return .Ok;
			}

			return .NotSuitable;
		}

		private bool isAccessModifier(TokenType type)
		{
			switch (type)
			{
			case .Public, .Internal, .Protected, .Private:
				return true;
			default:
				return false;
			}
		}

		private Result<void> parseAccessLevel(ref AccessLevel result)
		{
			while (isAccessModifier(_currentToken.Type))
			{
				if (result != .Undefined &&
					((result != .Internal && _currentToken.Type != .Private) &&
					 (result != .Protected && _currentToken.Type != .Internal)))
					raiseErrorF!(_currentToken.Position,
						"Modifier '{}' cannot be combined with '{}'", _lastToken.Type, _currentToken.Type);

				eat!(_currentToken.Type);
				switch (_lastToken.Type)
				{
				case .Public:
					result = .Public;
				case .Internal:
					switch (result)
					{
					case .Protected:
						result = .ProtectedInternal;
					default:
						result = .Internal;
					}
				case .Protected:
					switch (result)
					{
					case .Private:
						result = .PrivateProtected;
					default:
						result = .Protected;
					}
				case .Private:
					result = .Private;
				default:
					Debug.Assert(false, "Unknown switch case");
				}
			}

			return .Ok;
		}

		private bool isModifier(TokenType type)
		{
			switch (type)
			{
			case .Abstract, .Const, .Extern, .Override, .New, .Partial, .ReadOnly, .Sealed, .Unsafe, .Virtual, .Volatile, .Static:
				return true;
			default:
				return false;
			}
		}

		private Result<void> parseModifier(ref Modifier result)
		{
			while (isModifier(_currentToken.Type))
			{
				eat!(_currentToken.Type);
				switch (_lastToken.Type)
				{
				case .Abstract:
					if (result.HasFlag(.Abstract))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Abstract;
				case .Const:
					if (result.HasFlag(.Const))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Const;
				case .Extern:
					if (result.HasFlag(.Extern))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Extern;
				case .Override:
					if (result.HasFlag(.Override))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Override;
				case .New:
					if (result.HasFlag(.New))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .New;
				case .Partial:
					if (result.HasFlag(.Partial))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Partial;
				case .ReadOnly:
					if (result.HasFlag(.ReadOnly))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .ReadOnly;
				case .Sealed:
					if (result.HasFlag(.Sealed))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Sealed;
				case .Unsafe:
					if (result.HasFlag(.Unsafe))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Unsafe;
				case .Virtual:
					if (result.HasFlag(.Virtual))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Virtual;
				case .Volatile:
					if (result.HasFlag(.Volatile))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Volatile;
				case .Static:
					if (result.HasFlag(.Static))
						raiseErrorF!(_lastToken.Position, "Duplicate modifier '{}'", _lastToken.Type);
					result |= .Static;
				default:
					Debug.Assert(false, "Unknown switch case");
				}
			}

			return .Ok;
		}

		private bool isOpType(TokenType type)
		{
			switch (type)
			{
			case .Implicit, .Explicit:
				return true;
			default:
				return false;
			}
		}

		private Result<OperatorType> parseOpType()
		{
			OperatorType result = .None;
			while (isOpType(_currentToken.Type))
			{
				eat!(_currentToken.Type);
				switch (_lastToken.Type)
				{
				case .Implicit:
					if (result != .None)
						raiseErrorF!(_lastToken.Position, "'{}' already defined", _lastToken.Type);
					result = .Implicit;
				case .Explicit:
					if (result != .None)
						raiseErrorF!(_lastToken.Position, "'{}' already defined", _lastToken.Type);
					result = .Explicit;
				default:
					Debug.Assert(false, "Unknown switch case");
				}
			}

			return result;
		}

		private ParseResult<void> parseInheritance(ref List<TypeSpec> specs)
		{
			repeat
			{
				// We do this to make sure even the errored TypeSpec gets deleted with the parent node.
				TypeSpec* spec = specs.GrowUninitialized(1);
				*spec = null;
				Parse!(typeSpec(ref *spec));
			}
			while (tryEat!(TokenType.Comma));

			return .Ok;
		}

		private ParseResult<void> typeDecl(ref List<Declaration> decls, bool isNamespace)
		{
			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}
			
			List<AttributeSpec> attrs = new .();

			defer
			{
				if (!rollback.Cancelled)
					Release!(attrs);
			}

			while (TryParse!(parseAttributes(ref attrs))) { }

			AccessLevel level = .Undefined;
			Modifier modifier = .None;

			while (isModifier(_currentToken.Type) || isAccessModifier(_currentToken.Type))
			{
				Try!(parseAccessLevel(ref level));
				Try!(parseModifier(ref modifier));
			}

			BaseTypeDecl decl = null;

			if (tryEat!(TokenType.Interface))
			{
			    decl = new InterfaceDecl();
			}
			else if (tryEat!(TokenType.Class))
			{
			    decl = new ClassDecl();
			}
			else if (tryEat!(TokenType.Struct))
			{
			    decl = new StructDecl();
			}
			else if (tryEat!(TokenType.Enum))
			{
				decl = new EnumDecl();
			}
			else if (tryEat!(TokenType.Extension))
			{
			    decl = new ExtensionDecl();
			}
			else if (tryEat!(TokenType.Delegate))
			{
				let delegateDecl = new DelegateDecl();
				decl = delegateDecl;
				Parse!(typeSpec(ref delegateDecl.Specification));
			}
			else
			{
				return .NotSuitable;
			}
			
			rollback.Cancel();
			_usingAllowed = false;

			decls.Add(decl);
			
			decl.Attributes = attrs;
			decl.AccessLevel = decl.AccessLevel == .Undefined ? .Public : level;
			decl.Modifiers = modifier;

			eat!(TokenType.Identifier);
			decl.Name = _lastToken.AsText();

			if (isNamespace)
			{
				switch (decl.AccessLevel)
				{
				case .Public, .Internal:
					break;
				default:
					raiseError!(_lastToken.Position, "Elements defined in a namespace cannot be explicitly declared as private, protected, protected internal, or private protected");
				}
			}

			if (var typeDecl = decl as TypeDecl)
			{
				// Parse Generic Parameters
				if (tryEat!(TokenType.LArrow))
				{
					Try!(parseGenericParametersNames(ref typeDecl.GenericParametersNames));
					eat!(TokenType.RArrow);
				}

				// Parse Inheritance
				if (tryEat!(TokenType.Colon))
				{
					Try!(parseInheritance(ref typeDecl.Inheritance));
				}

				TryParse!(parseGenericConstraints(ref typeDecl.GenericConstraints));

				scope TemporaryChange<BaseTypeDecl>(ref _context.Type, decl);
	
				eat!(TokenType.LCurly);
				Try!(declarations(ref typeDecl.Declarations));
				eat!(TokenType.RCurly);
				return .Ok;
			}
			else if (var enumDecl = decl as EnumDecl)
			{
				scope TemporaryChange<BaseTypeDecl>(ref _context.Type, decl);

				if (tryEat!(TokenType.Colon))
				{
					// We do this to make sure even the errored TypeSpec gets deleted with the parent node.
					TypeSpec* underlyingType = enumDecl.Inheritance.GrowUninitialized(1);
					*underlyingType = null;
					Parse!(typeSpec(ref *underlyingType));
				}

				eat!(TokenType.LCurly);

				if (_currentToken.Type == .Case)
				{
					Try!(declarations(ref enumDecl.Declarations));
				}
				else
				{
					repeat
					{
						if(!tryEat!(TokenType.Identifier))
							break;
						
						// TODO: Attributes support
						var key = _lastToken.AsText();
	
						if (enumDecl.SimpleDeclarations.ContainsKeyAlt(key))
							raiseErrorF!(_lastToken.Position, "A field named '{}' has already been declared.", key);
	
						enumDecl.SimpleDeclarations.TryAddAlt(key, let keyPtr, let exprPtr);
						*keyPtr = new String(key);
						*exprPtr = null;
	
						if (tryEat!(TokenType.Assign))
							Parse!(expression(ref *exprPtr));
					} while (tryEat!(TokenType.Comma));
				}

				eat!(TokenType.RCurly);
				return .Ok;
			}
			else if (var delegateDecl = decl as DelegateDecl)
			{
				// Parse Generic Parameters
				if (tryEat!(TokenType.LArrow))
				{
					Try!(parseGenericParametersNames(ref delegateDecl.GenericParametersNames));
					eat!(TokenType.RArrow);
				}

				if (tryEat!(TokenType.LParen) && !tryEat!(TokenType.RParen))
				{
					Try!(parseFormalParameters(ref delegateDecl.FormalParameters));
					eat!(TokenType.RParen);
				}

				TryParse!(parseGenericConstraints(ref delegateDecl.GenericConstraints));
				return .Ok;
			}

			Runtime.NotImplemented();
		}

		private Result<void> paramDecl(ref ParamDecl paramDecl)
		{
			List<AttributeSpec> attrs = new .();
			while (TryParse!(parseAttributes(ref attrs))) { }

			paramDecl = new .()
			{
				Attributes = attrs
			};

			if (tryEat!(TokenType.In))
				paramDecl.IsIn = true;
			else if (tryEat!(TokenType.Out))
				paramDecl.IsOut = true;
			else if (tryEat!(TokenType.Ref))
				paramDecl.IsRef = true;

			Parse!(typeSpec(ref paramDecl.Specification));

			if (tryEat!(TokenType.Identifier))
				paramDecl.Name = _lastToken.AsText();

			if (tryEat!(TokenType.Assign))
			{
				scope TemporaryChange<ContextScopeType>(ref _context.ScopeType, .Assignment);

				Parse!(expression(ref paramDecl.Default));
			}

			return .Ok;
		}

		private ParseResult<void> variableDecl(ref VariableDecl varDecl, bool isField = false)
		{
			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			let tokenIndexBkp = _tokenIndex;

			// Little optimization to avoid unnecessary TypeSpec allocations
			if (!TryParse!(checkTypeSpec()))
				return .NotSuitable;

			// Now we can make sure that we are really dealing with a variable
			// <LEVEL> <MODIFIERS> <TYPE> <NAME> <SEMI>/<ASSIGN>/<COMMA>[/<TILDE>]
			if (_nextToken.Type == .Semi || _nextToken.Type == .Assign || _nextToken.Type == .Comma || (isField && _nextToken.Type == .Tilde))
			{
				rollback.Cancel();

				// Rollback to before the TypeSpec
				_tokenIndex = tokenIndexBkp;

				TypeSpec typeSpec = null;
				Parse!(typeSpec(ref typeSpec));

				varDecl = new VariableDecl()
				{
					Specification = typeSpec
				};

				repeat
				{
					eat!(TokenType.Identifier);
	
					let declarator = new VariableDeclarator()
					{
						Name = _lastToken.AsText()
					};
					varDecl.Variables.Add(declarator);
	
					if (tryEat!(TokenType.Assign))
					{
						scope TemporaryChange<ContextScopeType>(ref _context.ScopeType, .Assignment);
	
						Parse!(expression(ref declarator.Initializer));
					}

					if (isField)
					{
						if (tryEat!(TokenType.Tilde))
							Parse!(statement(ref declarator.Finalizer, false));
					}
				} while (tryEat!(TokenType.Comma));

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> fieldDecl(ref List<Declaration> decls)
		{
			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			List<AttributeSpec> attrs = new .();

			defer
			{
				if (!rollback.Cancelled)
					Release!(attrs);
			}

			while (TryParse!(parseAttributes(ref attrs))) { }

			AccessLevel level = .Undefined;
			Modifier modifier = .None;

			while (isModifier(_currentToken.Type) || isAccessModifier(_currentToken.Type))
			{
				Try!(parseAccessLevel(ref level));
				Try!(parseModifier(ref modifier));
			}

			VariableDecl varDecl = null;

			defer
			{
				if (!rollback.Cancelled)
					delete varDecl;
			}

			if (TryParse!(variableDecl(ref varDecl, true)))
			{
				if (!tryEat!(TokenType.Semi))
					raiseErrorF!(_currentToken.Position, "Expected \"Semi\" got \"{}\"", _currentToken.Type);
				
				rollback.Cancel();

				FieldDecl fieldDecl = new .()
				{
					Attributes = attrs,
					AccessLevel = level,
					Modifiers = modifier,
					Declaration = varDecl
				};
				decls.Add(fieldDecl);

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> parsePropertyAccessors(ref List<PropertyAccessor> accessors)
		{
			if (tryEat!(TokenType.Bind))
			{
				let accessor = new PropertyAccessor(.Undefined)
				{
					AccessorType = .Get
				};
				accessors.Add(accessor);

				Parse!(expression(ref accessor.Expr));
				eat!(TokenType.Semi);
				return .Ok;
			}

			if (tryEat!(TokenType.LCurly))
			{
				while (!tryEat!(TokenType.RCurly))
				{
					List<AttributeSpec> accessorAttrs = new .();
					while (TryParse!(parseAttributes(ref accessorAttrs))) { }

					AccessLevel propLevel = .Undefined;
					Try!(parseAccessLevel(ref propLevel));

					if (tryEat!(TokenType.Get))
					{
						let accessor = new PropertyAccessor(propLevel)
						{
							AccessorType = .Get,
							Attributes = accessorAttrs
						};
						accessors.Add(accessor);

						if (tryEat!(TokenType.Bind))
						{
							Parse!(expression(ref accessor.Expr));
							eat!(TokenType.Semi);
						}
						else if (_currentToken.Type == .LCurly)
						{
							Parse!(compoundStatement(ref accessor.Statement));
						}
						else
						{
							eat!(TokenType.Semi);
						}
					}
					else if (tryEat!(TokenType.Set))
					{
						let accessor = new PropertyAccessor(propLevel)
						{
							AccessorType = .Set,
							Attributes = accessorAttrs
						};
						accessors.Add(accessor);

						if (tryEat!(TokenType.Bind))
						{
							Parse!(expression(ref accessor.Expr));
							eat!(TokenType.Semi);
						}
						else if (_currentToken.Type == .LCurly)
						{
							Parse!(compoundStatement(ref accessor.Statement));
						}
						else
						{
							eat!(TokenType.Semi);
						}
					}
					else
					{
						if (accessors.IsEmpty)
							return .NotSuitable;

						raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
					}
				}

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> propertyDecl(ref List<Declaration> decls)
		{
			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			List<AttributeSpec> attrs = new .();

			defer
			{
				if (!rollback.Cancelled)
					Release!(attrs);
			}

			while (TryParse!(parseAttributes(ref attrs))) { }

			AccessLevel level = .Undefined;
			Modifier modifier = .None;

			while (isModifier(_currentToken.Type) || isAccessModifier(_currentToken.Type))
			{
				Try!(parseAccessLevel(ref level));
				Try!(parseModifier(ref modifier));
			}

			TypeSpec typeSpec = null;
			if (!TryParse!(typeSpec(ref typeSpec)))
				return .NotSuitable;

			defer
			{
				if (!rollback.Cancelled)
					delete typeSpec;
			}

			let tokenIndexBkp = _tokenIndex;

			if (TryParse!(checkParseName()))
			{
				_tokenIndex -= 1;
			}
			else
			{
				return .NotSuitable;
			}

			// Now we can make sure that we are really dealing with a property
			// <LEVEL> <MODIFIERS> <TYPE> <NAME> <SEMI>/<EQUAL>
			// or
			// <LEVEL> <MODIFIERS> <TYPE> <NAME>[<PARAMS>] <SEMI>/<EQUAL>
			if (_nextToken.Type == .Bind || _nextToken.Type == .LCurly || _nextToken.Type == .LBracket)
			{
				rollback.Cancel();

				_tokenIndex = tokenIndexBkp;

				Name name = null;
				if (!TryParse!(parseName(ref name)))
					raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
				_tokenIndex -= 1;

				Name explicitInterfaceName = null;
				if (let qualifiedName = name as QualifiedName)
					Swap!(explicitInterfaceName, qualifiedName.Left);

				delete name;

				BasePropertyDecl decl = null;

				if (_nextToken.Type != .LBracket)
					decl = new PropertyDecl();
				else
					decl = new IndexPropertyDecl();

				decl.Attributes = attrs;
				decl.AccessLevel = level;
				decl.Modifiers = modifier;
				decl.Specification = typeSpec;
				decl.ExplicitInterfaceName = explicitInterfaceName;

				decls.Add(decl);

				eat!(TokenType.Identifier);
				decl.Name = _lastToken.AsText();

				if ((var indexPropertyDecl = decl as IndexPropertyDecl) && tryEat!(TokenType.LBracket) && !tryEat!(TokenType.RBracket))
				{
					Try!(parseFormalParameters(ref indexPropertyDecl.FormalParameters));
					eat!(TokenType.RBracket);
				}

				Parse!(parsePropertyAccessors(ref decl.Accessors));

				if (decl.Accessors.IsEmpty)
					raiseErrorF!(_lastToken.Position, "Property or indexer '{}' must have at least one accessor", decl.Name);

				return .Ok;
			}

			return .NotSuitable;
		}

		private Result<void> parseGenericParametersNames(ref List<String> strs)
		{
			repeat
			{
				eat!(TokenType.Identifier);
				strs.Add(new .(_lastToken.AsText()));
			}
			while (tryEat!(TokenType.Comma));

			return .Ok;
		}

		private Result<void> parseFormalParameters(ref List<ParamDecl> vars)
		{
			repeat
			{
				// We do this to make sure even the errored ParamDecl gets deleted with the parent node.
				ParamDecl* decl = vars.GrowUninitialized(1);
				*decl = null;
				Try!(paramDecl(ref *decl));
			}
			while (tryEat!(TokenType.Comma));

			return .Ok;
		}

		private ParseResult<void> parseAttributes(ref List<AttributeSpec> attrs)
		{
			if (!tryEat!(TokenType.LBracket))
				return .NotSuitable;

			repeat
			{
				AttributeSpec spec = new .();
				attrs.Add(spec);

				if (_currentToken.Type == TokenType.Return && _nextToken.Type == TokenType.Colon)
				{
					eat!(TokenType.Return);
					eat!(TokenType.Colon);
					spec.IsReturn = true;
				}
				else if (_currentToken.Type == TokenType.Identifier && _currentToken.AsText() == "assembly" && _nextToken.Type == TokenType.Colon)
				{
					eat!(TokenType.Identifier);
					eat!(TokenType.Colon);
					spec.IsAssembly = true;
				}

				Parse!(typeSpec(ref spec.TypeSpec));

				if (tryEat!(TokenType.LParen) && !tryEat!(TokenType.RParen))
				{
					Parse!(parseCommaSeparatedExprList(ref spec.Arguments));
					eat!(TokenType.RParen);
				}
			}
			while (tryEat!(TokenType.Comma));

			eat!(TokenType.RBracket);
			return .Ok;
		}

		private ParseResult<void> parseGenericConstraints(ref List<GenericConstraintDecl> constraints)
		{
			if (!tryEat!(TokenType.Where))
				return .NotSuitable;

			repeat
			{
				eat!(isReservedType(_currentToken.Type) ? _currentToken.Type : TokenType.Identifier);

				var targetStr = _lastToken.AsText();
	
				eat!(TokenType.Colon);

				GenericConstraintDecl decl = new .()
				{
					Target = targetStr
				};
				constraints.Add(decl);

				repeat
				{
					if (tryEat!(TokenType.Struct))
						decl.Constraints.Add(new StructConstraint());
					else if (tryEat!(TokenType.Class))
						decl.Constraints.Add(new ClassConstraint());
					else if (tryEat!(TokenType.Default))
						decl.Constraints.Add(new DefaultConstraint());
					else if (tryEat!(TokenType.New))
						decl.Constraints.Add(new ConstructorConstraint());
					else if (tryEat!(TokenType.Delete))
						decl.Constraints.Add(new DestructorConstraint());
					else if (tryEat!(TokenType.Operator))
					{
						let binaryOpConstraint = new TypeBinaryOpConstraint();
						decl.Constraints.Add(binaryOpConstraint);
						
						Parse!(typeSpec(ref binaryOpConstraint.Left));
						binaryOpConstraint.Operation = _currentToken.Type;
						eat!(_currentToken.Type);
						Parse!(typeSpec(ref binaryOpConstraint.Right));
					}
					else
					{
						TypeConstraint typeConstraint = new TypeConstraint();
						decl.Constraints.Add(typeConstraint);

						Parse!(typeSpec(ref typeConstraint.TypeSpec));
					}
				}
				while (tryEat!(TokenType.Comma));
			}
			while (tryEat!(TokenType.Where));

			return .Ok;
		}
		
		private ParseResult<void> methodDecl(ref List<Declaration> decls)
		{
			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			List<AttributeSpec> attrs = new .();

			defer
			{
				if (!rollback.Cancelled)
					Release!(attrs);
			}

			while (TryParse!(parseAttributes(ref attrs))) { }

			AccessLevel level = .Undefined;
			Modifier modifier = .None;

			while (isModifier(_currentToken.Type) || isAccessModifier(_currentToken.Type))
			{
				Try!(parseAccessLevel(ref level));
				Try!(parseModifier(ref modifier));
			}

			OperatorType opType = .None;

			bool isConstructor = false;
			bool isDestructor = false;
			bool isOperator = false;
			bool isMixin = false;
			TypeSpec typeSpec = null;

			if (_currentToken.Type == TokenType.Tilde && _nextToken.Type == TokenType.Identifier)
			{
				eat!(TokenType.Tilde);
				if (_currentToken.AsText() == "this")
				{
					// Destructor declaration.
					isDestructor = true;
				}
				else
				{
					raiseError!(_currentToken.Position, "Method return type expected");
				}
			}
			else if (_currentToken.Type == TokenType.Identifier && _nextToken.Type == .LParen)
			{
				if (_currentToken.AsText() == "this")
				{
					// Constructor declaration.
					isConstructor = true;
				}
				else
				{
					raiseError!(_currentToken.Position, "Method return type expected");
				}
			}
			else
			{
				opType = Try!(parseOpType());

				if (opType != .None)
				{
					eat!(TokenType.Operator);
					isOperator = true;
				}
				else if (tryEat!(TokenType.Operator))
				{
					opType = .Implicit; // Default value?
					isOperator = true;
				}

				if (tryEat!(TokenType.Mixin))
					isMixin = true;
				else if (!TryParse!(typeSpec(ref typeSpec)))
					return .NotSuitable;

				defer::
				{
					if (!rollback.Cancelled)
						delete typeSpec;
				}
			}

			bool isMethod = false;
			if (!isOperator)
			{
				isMethod = _nextToken.Type == .LParen || _nextToken.Type == .LArrow || _nextToken.Type == .Dot;
			}
			else
			{
				isMethod = _currentToken.Type == .LParen;
			}

			// Now we can make sure that we are really dealing with a method
			// <LEVEL> <MODIFIERS> <TYPE> [<INTERFACE>].<NAME> <LPAREN>/<LARROW>
			if (isMethod)
			{
				rollback.Cancel();

				var decl = new MethodDecl()
				{
					Attributes = attrs,
					AccessLevel = level,
					Modifiers = modifier,
					Specification = typeSpec,
					IsConstructor = isConstructor,
					IsDestructor = isDestructor,
					IsOperator = isOperator,
					IsMixin = isMixin,
					OperatorType = opType
				};
				decls.Add(decl);

				if (!isOperator)
				{
					eat!(TokenType.Identifier);

					if (tryEat!(TokenType.Dot))
					{
						decl.InterfaceName = _lastToken.AsText();
						eat!(TokenType.Identifier);
						decl.Name = _lastToken.AsText();
					}
					else
					{
						decl.Name = _lastToken.AsText();
					}

					// Parse Generic Parameters
					if (tryEat!(TokenType.LArrow))
					{
						Try!(parseGenericParametersNames(ref decl.GenericParametersNames));
						eat!(TokenType.RArrow);
					}
				}

				if (tryEat!(TokenType.LParen) && !tryEat!(TokenType.RParen))
				{
					Try!(parseFormalParameters(ref decl.FormalParameters));
					eat!(TokenType.RParen);
				}

				decl.IsMutable = tryEat!(TokenType.Mut);

				if (isConstructor && tryEat!(TokenType.Colon))
				{
					Expression expr = null;
					Parse!(identifierExpr(ref expr));
					
					eat!(TokenType.LParen);

					decl.InhenritanceCall = new CallOpExpr()
					{
						Expr = expr
					};

					if (!tryEat!(TokenType.RParen))
					{
						Parse!(parseCommaSeparatedExprList(ref decl.InhenritanceCall.Params));
						eat!(TokenType.RParen);
					}
				}

				TryParse!(parseGenericConstraints(ref decl.GenericConstraints));

				scope TemporaryChange<MethodDecl>(ref _context.Method, decl);

				bool hasBody = TryParse!(compoundStatement(ref decl.CompoundStmt));
				if (!hasBody)
				{
					if (_currentToken.Type == TokenType.Semi && !decl.Modifiers.HasFlag(.Abstract) && !decl.Modifiers.HasFlag(.Extern) && _context.Type.GetType() != typeof(InterfaceDecl) && !_context.Type.Modifiers.HasFlag(.Abstract))
						raiseError!(_currentToken.Position, "Non-abstract and non-extern method must declare a body");
					eat!(TokenType.Semi);
				}

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> typeAliasDecl(ref List<Declaration> decls)
		{
			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			AccessLevel level = .Undefined;

			while (isAccessModifier(_currentToken.Type))
			{
				Try!(parseAccessLevel(ref level));
			}

			if (tryEat!(TokenType.TypeAlias))
			{
				rollback.Cancel();
				_usingAllowed = false;

				eat!(TokenType.Identifier);

				let typeAlias = new TypeAliasDecl()
				{
					Name = _lastToken.AsText()
				};
				decls.Add(typeAlias);

				// Parse Generic Parameters
				if (tryEat!(TokenType.LArrow))
				{
					Try!(parseGenericParametersNames(ref typeAlias.GenericParametersNames));
					eat!(TokenType.RArrow);
				}

				eat!(TokenType.Assign);

				Parse!(typeSpec(ref typeAlias.TypeSpec));
				eat!(TokenType.Semi);

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> parseEnumCase(ref List<Declaration> decls)
		{
		    if (!tryEat!(TokenType.Case))
		        return .NotSuitable;

			if (!(_context.Type is EnumDecl))
				raiseError!(_currentToken.Position, "Enum cases can only be declared within enum types.");

		    var caseDecl = new EnumCaseDecl();
		    decls.Add(caseDecl);

		    repeat
		    {
		        var item = new EnumCaseItem();

		        eat!(TokenType.Identifier);
		        item.Name = _lastToken.AsText();

		        if (tryEat!(TokenType.LParen))
		        {
		            if (_currentToken.Type != TokenType.RParen)
		                Try!(parseFormalParameters(ref item.Parameters));
		            eat!(TokenType.RParen);
		        }

		        caseDecl.Items.Add(item);

		    } while (tryEat!(TokenType.Comma));

		    eat!(TokenType.Semi);

		    return .Ok;
		}

		private Result<void> declarations(ref List<Declaration> decls, bool isNamespace = false)
		{
			while (_currentToken.Type != .RCurly && _currentToken.Type != .EOF)
			{
				if (tryEat!(TokenType.Semi))
					continue;

				TryParseContinue!(usingDirective());
				TryParseContinue!(namespaceDecl(ref decls));
				TryParseContinue!(typeAliasDecl(ref decls));
				TryParseContinue!(typeDecl(ref decls, isNamespace));

				if (!isNamespace)
				{
					TryParseContinue!(parseEnumCase(ref decls));
					TryParseContinue!(fieldDecl(ref decls));
					TryParseContinue!(propertyDecl(ref decls));
					TryParseContinue!(methodDecl(ref decls));
				}

				if (_lastFailureIndex != -1)
					raiseErrorF!(_tokens[_lastFailureIndex].Position, "Unexpected token '{}'", _tokens[_lastFailureIndex].Type);
				else
					raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
			}

			_lastFailureIndex = -1;
			return .Ok;
		}

		private ParseResult<void> identifierExpr(ref Expression expr, bool eatAnything = false)
		{
			if (!tryEat!(eatAnything ? _currentToken.Type : TokenType.Identifier))
				return .NotSuitable;

			ensureNull!(expr) = new IdentifierExpr(_lastToken.AsText());
			return .Ok;
		}

		private ParseResult<void> constantExpr(ref Expression expr)
		{
			switch (_currentToken.Type)
			{
			case .Null:
				eat!(_currentToken.Type);
				ensureNull!(expr) = new NullLiteral();
				return .Ok;
			case .True, .False:
				eat!(_currentToken.Type);
				ensureNull!(expr) = new BoolLiteral(_lastToken.Type == .True);
				return .Ok;
			case .IntegerLiteral:
				eat!(_currentToken.Type);
				ensureNull!(expr) = new IntLiteral(_lastToken.AsInteger());
				return .Ok;
			case .FloatLiteral, .DoubleLiteral:
				eat!(_currentToken.Type);
				ensureNull!(expr) = new RealLiteral(_lastToken.Type, _lastToken.AsReal());
				return .Ok;
			case .StringLiteral:
				eat!(_currentToken.Type);
				ensureNull!(expr) = new StrLiteral(_lastToken.AsText());
				return .Ok;
			case .CharLiteral:
				eat!(_currentToken.Type);
				ensureNull!(expr) = new CharLiteral(_lastToken.AsText().DecodedChars.GetNext());
				return .Ok;
			default:
				return .NotSuitable;
			}
		}

		private bool isConstant(TokenType type)
		{
			switch (type)
			{
			case .True, .False, .Null, .IntegerLiteral, .FloatLiteral, .DoubleLiteral, .StringLiteral, .CharLiteral:
				return true;
			default:
				return false;
			}
		}

		private List<String> _lambdaParametersReusableList ~ Release!(_);
		private ParseResult<void> lambdaOpExpr(ref Expression expr, bool expectParens = false)
		{
			// X/(X) => X/{X}

			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			// This is called for almost ALL identifiers, even if they aren't part of a lambda expression,
			// so to avoid tons of unnecessary allocations we use an reusable list here.
			if (_lambdaParametersReusableList == null)
				_lambdaParametersReusableList = new .();
			else
				_lambdaParametersReusableList.ClearAndDeleteItems();
			
			if (!expectParens)
			{
				if (_nextToken.Type != TokenType.Bind)
					return .NotSuitable;

				if (!tryEat!(isReservedType(_currentToken.Type) ? _currentToken.Type : TokenType.Identifier))
					return .NotSuitable;

				_lambdaParametersReusableList.Add(new .(_lastToken.AsText()));
			}
			else
			{
				eat!(TokenType.LParen);

				if (!tryEat!(TokenType.RParen))
				{
					repeat
					{
						// TODO: explicit lambda parameter type?

						if (_nextToken.Type != .Comma && _nextToken.Type != .RParen)
							return .NotSuitable;

						if (!tryEat!(isReservedType(_currentToken.Type) ? _currentToken.Type : TokenType.Identifier))
							return .NotSuitable;
	
						_lambdaParametersReusableList.Add(new .(_lastToken.AsText()));
					}
					while (tryEat!(TokenType.Comma));
	
					if (!tryEat!(TokenType.RParen))
						return .NotSuitable;
				}
			}

			if (!tryEat!(TokenType.Bind))
				return .NotSuitable;

			rollback.Cancel();
			
			ensureNull!(expr);
			var lambdaOpExpr = new LambdaOpExpr();
			expr = lambdaOpExpr;

			Swap!(lambdaOpExpr.FormalParameters, _lambdaParametersReusableList);

			if (TryParse!(compoundStatement(ref lambdaOpExpr.Statement)))
				return .Ok;

			Debug.Assert(lambdaOpExpr.Statement == null);
			Parse!(expression(ref lambdaOpExpr.Expr));
			return .Ok;
		}

		public ParseResult<void> arrayInitExpr(ref ArrayInitExpr arrayInitExpr)
		{
			if (_currentToken.Type != .LCurly && _currentToken.Type != .LParen)
				return .NotSuitable;

			if (!tryEat!(TokenType.LCurly))
				eat!(TokenType.LParen);

			arrayInitExpr = new .();

			// Treat "{ X }" as Collection Item Initializer
			scope TemporaryChange<ContextScopeType>(ref _context.ScopeType, .MemberInit);

			repeat
			{
				if (_currentToken.Type == TokenType.RCurly || _currentToken.Type == TokenType.RParen)
					break;

				// We do this to make sure even the errored Expression gets deleted with the parent node.
				Expression* expr = arrayInitExpr.Values.GrowUninitialized(1);
				*expr = null;
				Parse!(expression(ref *expr));
			}
			while (tryEat!(TokenType.Comma));

			if (!tryEat!(TokenType.RCurly))
				eat!(TokenType.RParen);
			return .Ok;
		}

		public ParseResult<void> objectInitExpr(ref ObjectInitExpr objectInitExpr)
		{
			if (_currentToken.Type != .LCurly)
				return .NotSuitable;
			else if (_nextToken.Type == .RCurly)
			{
				eat!(TokenType.LCurly);
				eat!(TokenType.RCurly);
				objectInitExpr = new .();
				return .Ok;
			}

			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			eat!(TokenType.LCurly);

			// Treat "{ X }" as Collection Item Initializer
			scope TemporaryChange<ContextScopeType>(ref _context.ScopeType, .MemberInit);

			repeat
			{
				if (_currentToken.Type == .RCurly)
					break;

				Expression leftExpr = null;
				if (!TryParse!(identifierExpr(ref leftExpr)))
				{
					if (objectInitExpr == null)
						return .NotSuitable;
					raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
				}

				if (!tryEat!(TokenType.Assign))
				{
					delete leftExpr;
					if (objectInitExpr == null)
						return .NotSuitable;
					raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
				}

				if (objectInitExpr == null)
					objectInitExpr = new .();

				AssignExpr assignExpr = new .()
				{
					Left = leftExpr
				};
				objectInitExpr.Initializers.Add(assignExpr);

				scope TemporaryChange<ContextScopeType>(ref _context.ScopeType, .Assignment);

				Parse!(expression(ref assignExpr.Right));
			}
			while (tryEat!(TokenType.Comma));

			eat!(TokenType.RCurly);

			rollback.Cancel();
			return .Ok;
		}

		private ParseResult<void> interpolatedStringExpr(ref Expression expr)
		{
			InterpolatedStringExpr interpolatedExpr = null;
			while (true)
			{
				tryEat!(_currentToken.Type);
				switch (_lastToken.Type)
				{
				case .InterpolatedStringStart:
					int braceCount = _lastToken.AsText().Length;
					interpolatedExpr = new InterpolatedStringExpr(braceCount);
					expr = interpolatedExpr;
				case .InterpolatedStringEnd:
					return .Ok;
				case .InterpolatedStringText:
					interpolatedExpr.Exprs.Add(new StrLiteral(_lastToken.AsText()));
				case .InterpolationStart:
					Expression expression = null;
					Parse!(expression(ref expression));
					interpolatedExpr.Exprs.Add(expression);
					eat!(TokenType.InterpolationEnd);
				default:
					raiseErrorF!(_lastToken.Position, "Unexpected token '{}'", _lastToken.Type);
				}
			}
		}

		private ParseResult<void> primaryExpr(ref Expression expr)
		{
			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex, true);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			// If we are here, then this reserved type should be treated as an identifier.
			if (isReservedType(_currentToken.Type))
				TryParseReturn!(identifierExpr(ref expr, true));

			switch (_currentToken.Type)
			{
			case .LBracket:
				ensureNull!(expr);
				let attributedExpr = new AttributedExpr();
				expr = attributedExpr;

				while (TryParse!(parseAttributes(ref attributedExpr.Attributes))) { }
				Parse!(primaryExpr(ref attributedExpr.Expr));
				return .Ok;
			case .InterpolatedStringStart:
				if (!TryParse!(interpolatedStringExpr(ref expr)))
				{
					raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
				}
				return .Ok;
			case .Identifier:
				TryParseReturn!(lambdaOpExpr(ref expr, false));
				TryParseReturn!(identifierExpr(ref expr));
				break;
			case .LParen:
				// Cast = (Expression)Expression
				// Enclosing = (Expression)
				// Tuple = (Identifier, ...)
				// Lambda = (Identifier) => ...
				TryParseReturn!(lambdaOpExpr(ref expr, true));

				eat!(TokenType.LParen);

				if (expr != null)
					Debug.Break(); // Shouldn't happen.

				if (!TryParse!(expression(ref expr)))
				{
					rollback.Rollback();
					return .NotSuitable;
				}

				eat!(TokenType.RParen);
				return .Ok;
			case .LCurly when _context.ScopeType == .Assignment || _context.ScopeType == .MemberInit:
				// TODO: Don't allow this case when we aren't currently in an array scope.
				ArrayInitExpr arrayInitExpr = null;
				if (!TryParse!(arrayInitExpr(ref arrayInitExpr)))
				{
					rollback.Rollback();
					return .NotSuitable;
				}

				ensureNull!(expr) = arrayInitExpr;
				return .Ok;
			case .QuestionMark:
				eat!(TokenType.QuestionMark);
				ensureNull!(expr) = new UninitializedExpr();
				return .Ok;
			default:
				break;
			}

			return constantExpr(ref expr);
		}

		private ParseResult<void> parseCommaSeparatedExprList(ref List<Expression> exprs)
		{
			repeat
			{
				// We do this to make sure even the errored Expression gets deleted with the parent node.
				Expression* expr = exprs.GrowUninitialized(1);
				*expr = null;
				Parse!(expression(ref *expr));
			}
			while (tryEat!(TokenType.Comma));

			return .Ok;
		}

		private ParseResult<void> postFixExpr(ref Expression expr)
		{
			TryParse!(primaryExpr(ref expr));

			if (expr == null)
				return .NotSuitable;

			postFixLoop:
			while (tryEat!(TokenType.Not) ||
				   tryEat!(TokenType.LArrow) ||
				   tryEat!(TokenType.LParen) ||
				   tryEat!(TokenType.LBracket) ||
				   tryEat!(TokenType.DoubleColon) ||
				   tryEat!(TokenType.Dot) ||
				   tryEat!(TokenType.DotDot) ||
				   tryEat!(TokenType.DotDotDot) ||
				   tryEat!(TokenType.UpToRange) ||
				   tryEat!(TokenType.NullCond) ||
				   tryEat!(TokenType.Increment) ||
				   tryEat!(TokenType.Decrement))
			{
				switch (_lastToken.Type)
				{
				case .Not:
					expr = new MixinMemberExpr()
					{
						Expr = expr
					};
				case .LArrow:
					// The rollback needs to be set before the LArrow was eaten.
					_tokenIndex--;
					ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);
					_tokenIndex++;

					List<TypeSpec> genParams = new .();

					defer
					{
						if (!rollback.Cancelled)
							Release!(genParams);
					}

					if ((parseGenericParameters(ref genParams) case .Ok) &&
						tryEat!(TokenType.RArrow))
					{
						rollback.Cancel();

						expr = new GenericMemberExpr()
						{
							Left = expr,
							GenericParameters = genParams
						};
						continue postFixLoop;
					}

					// Not generic member expression.
					break postFixLoop;
				case .LParen:
					let callOpExpr = new CallOpExpr()
					{
						Expr = expr
					};
					expr = callOpExpr;

					if (!tryEat!(TokenType.RParen))
					{
						Parse!(parseCommaSeparatedExprList(ref callOpExpr.Params));
						eat!(TokenType.RParen);
					}
				case .LBracket:
					let indexOpExpr = new IndexOpExpr()
					{
						Left = expr
					};
					expr = indexOpExpr;

					Parse!(parseCommaSeparatedExprList(ref indexOpExpr.Indexes));
					eat!(TokenType.RBracket);
				case .DoubleColon:
					var ident = expr as IdentifierExpr;
					if (ident == null)
						raiseError!(_lastToken.Position, "Expected identifier.");
					
					let memberExpr = new AliasedNamespaceMemberExpr()
					{
						Alias = ident
					};
					expr = memberExpr;

					Parse!(primaryExpr(ref memberExpr.Right));
				case .Dot, .NullCond:
					let memberExpr = new MemberExpr()
					{
						Left = expr,
						IsNullable = _lastToken.Type == .NullCond
					};
					expr = memberExpr;

					Parse!(primaryExpr(ref memberExpr.Right));
				case .DotDot:
					let memberExpr = new CascadeMemberExpr()
					{
						Left = expr
					};
					expr = memberExpr;

					Parse!(primaryExpr(ref memberExpr.Right));
				case .DotDotDot, .UpToRange:
					let rangeExpr = new RangeExpr()
					{
						Left = expr,
						Type = _lastToken.Type
					};
					expr = rangeExpr;

					Parse!(primaryExpr(ref rangeExpr.Right));
				default:
					expr = new PostfixOpExpr()
					{
						Operation = _lastToken.Type,
						Left = expr
					};
				}
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> unaryExpr(ref Expression expr)
		{
			if (_currentToken.Type == .LParen)
			{
				let tokenIndexBkp = _tokenIndex;

				eat!(TokenType.LParen);

				// A little optimization to avoid unnecessary TypeSpec allocations
				if (TryParse!(checkTypeSpec()))
				{
					if (tryEat!(TokenType.RParen))
					{
						Expression expr2 = null;
						switch (expression(ref expr2))
						{
						case .Ok:
							let tokenIndexBkp2 = _tokenIndex;

							// Rollback to before the LParen
							_tokenIndex = tokenIndexBkp;

							eat!(TokenType.LParen);
							
							TypeSpec typeSpec = null;
							Parse!(typeSpec(ref typeSpec));

							eat!(TokenType.RParen);

							// Advance back to after the expression
							_tokenIndex = tokenIndexBkp2;

							ensureNull!(expr) = new CastExpr()
							{
								Expr = expr2,
								TypeSpec = typeSpec
							};

							return .Ok;
						case .NotSuitable:
							delete expr2;
							break;
						case .Err:
							delete expr2;
							raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
						}
					}
				}

				_tokenIndex = tokenIndexBkp;
			}
			else if (tryEat!(TokenType.New) || tryEat!(TokenType.Scope) || tryEat!(TokenType.Append))
			{
				bool isAppend = _lastToken.Type == .Append;
				bool isScope = _lastToken.Type == .Scope;
				TypeSpec typeSpec = null;
				
				BindType bind = .Undefined;
				if (tryEat!(TokenType.Colon))
				{
					if (tryEat!(TokenType.Mixin))
					{
						bind = .Mixin;
					}
					else
					{
						bind = .Custom(null);
						if (bind case .Custom(var ref bindExpr))
							Parse!(expression(ref bindExpr));
					}
				}
				else if (tryEat!(TokenType.DoubleColon))
				{
					bind = .RootScope;
				}

				if (tryEat!(TokenType.LBracket))
				{
					int commaCount = 0;
					while (tryEat!(TokenType.Comma))
						commaCount++;

					eat!(TokenType.RBracket);

					ensureNull!(expr) = new NewArrayImplicitOpExpr()
					{
						IsScope = isScope,
						IsAppend = isAppend,
						Bind = bind,
						CommaCount = commaCount
					};

					return .Ok;
				}
				else if (_currentToken.Type == .InterpolatedStringStart)
				{
					// TODO: Is here the most optimal place to parse this...?
					ensureNull!(expr);
					let newInterpolatedExpr = new NewInterpolatedStringOpExpr()
					{
						IsScope = isScope,
						IsAppend = isAppend,
						Bind = bind,
					};
					expr = newInterpolatedExpr;
					return primaryExpr(ref newInterpolatedExpr.Expr);
				}
				else if (_currentToken.Type == .LParen)
				{
					// TODO: Is here the most optimal place to parse this...?
					ensureNull!(expr);
					let newLambdaExpr = new NewLambdaOpExpr()
					{
						IsScope = isScope,
						IsAppend = isAppend,
						Bind = bind,
					};
					expr = newLambdaExpr;
					return primaryExpr(ref newLambdaExpr.Expr);
				}
				else
				{
					Parse!(typeSpec(ref typeSpec));

					if (expr != null)
					{
						let newOpExpr = (NewArrayImplicitOpExpr)expr;
						Parse!(arrayInitExpr(ref newOpExpr.Initializer));
					}
					else if (let arrayType = typeSpec as ArrayTypeSpec)
					{
						let newOpExpr = new NewArrayOpExpr()
						{
							IsScope = isScope,
							IsAppend = isAppend,
							Bind = bind,
							TypeSpec = arrayType
						};
						expr = newOpExpr;
	
						TryParse!(arrayInitExpr(ref newOpExpr.Initializer));
					}
					else
					{
						let newOpExpr = new NewOpExpr()
						{
							IsScope = isScope,
							IsAppend = isAppend,
							Bind = bind,
							TypeSpec = typeSpec
						};
						expr = newOpExpr;
	
						if (tryEat!(TokenType.LParen))
						{
							if (!tryEat!(TokenType.RParen))
							{
								newOpExpr.Arguments = new .();
								Parse!(parseCommaSeparatedExprList(ref newOpExpr.Arguments));
								eat!(TokenType.RParen);
							}
						}
						else if (_currentToken.Type != .LCurly)
							raiseError!(_currentToken.Position, "A new expression requires (), [], or {} after type");
	
						ObjectInitExpr* objectInitExpr = (.)&newOpExpr.Initializer;
						if (!TryParse!(objectInitExpr(ref *objectInitExpr)))
						{
							ArrayInitExpr* arrayInitExpr = (.)&newOpExpr.Initializer;
							TryParse!(arrayInitExpr(ref *arrayInitExpr));
						}
					}

					return .Ok;
				}
			}
			else if (tryEat!(TokenType.Delete))
			{
				ensureNull!(expr);
				let deleteOpExpr = new DeleteOpExpr();
				expr = deleteOpExpr;

				Parse!(expression(ref deleteOpExpr.Expr));
				return .Ok;
			}
			else if (tryEat!(TokenType.TypeOf))
			{
				eat!(TokenType.LParen);

				ensureNull!(expr);
				var typeOfOpExpr = new TypeOfOpExpr();
				expr = typeOfOpExpr;

				Parse!(typeSpec(ref typeOfOpExpr.TypeSpec));

				eat!(TokenType.RParen);
			}
			else if (tryEat!(TokenType.SizeOf))
			{
				eat!(TokenType.LParen);
				
				ensureNull!(expr);
				let sizeOfOpExpr = new SizeOfOpExpr();
				expr = sizeOfOpExpr;

				Parse!(typeSpec(ref sizeOfOpExpr.TypeSpec));

				eat!(TokenType.RParen);
			}
			else if (_currentToken.Type == .Default && _nextToken.Type != .Colon)
			{
				eat!(TokenType.Default);

				ensureNull!(expr);
				let defaultOpExpr = new DefaultOpExpr();
				expr = defaultOpExpr;

				if (tryEat!(TokenType.LParen))
				{
					Parse!(typeSpec(ref defaultOpExpr.TypeSpec));
					eat!(TokenType.RParen);
				}
			}
			else if (tryEat!(TokenType.Out))
			{
				ensureNull!(expr);
				let outExpr = new OutExpr();
				expr = outExpr;

				Parse!(unaryExpr(ref outExpr.Expr));
				return .Ok;
			}
			else if (tryEat!(TokenType.Ref))
			{
				ensureNull!(expr);
				let refExpr = new RefExpr();
				expr = refExpr;

				Parse!(unaryExpr(ref refExpr.Expr));
				return .Ok;
			}
			else if (tryEat!(TokenType.Var))
			{
				ensureNull!(expr);
				let refExpr = new VarExpr();
				expr = refExpr;

				Parse!(unaryExpr(ref refExpr.Expr));
				return .Ok;
			}
			else if (tryEat!(TokenType.Let))
			{
				ensureNull!(expr);
				let refExpr = new LetExpr();
				expr = refExpr;

				Parse!(unaryExpr(ref refExpr.Expr));
				return .Ok;
			}
			else if (tryEat!(TokenType.Mul))
			{
				ensureNull!(expr);
				let pointerExpr = new PointerIndirectionExpr();
				expr = pointerExpr;

				Parse!(unaryExpr(ref pointerExpr.Expr));
				return .Ok;
			}
			else if (tryEat!(TokenType.BitwiseAnd))
			{
				ensureNull!(expr);
				let addressOfExpr = new AddressOfExpr();
				expr = addressOfExpr;

				Parse!(unaryExpr(ref addressOfExpr.Expr));
				return .Ok;
			}
			else if (tryEat!(TokenType.Plus) ||
			    tryEat!(TokenType.Minus) ||
				tryEat!(TokenType.Not) ||
				tryEat!(TokenType.Tilde) || // BitwiseNot
			    tryEat!(TokenType.Increment) ||
			    tryEat!(TokenType.Decrement))
			{
				ensureNull!(expr);
				let unaryOpExpr = new UnaryOpExpr()
				{
					Operation = _lastToken.Type
				};
				expr = unaryOpExpr;

				Parse!(unaryExpr(ref unaryOpExpr.Right));
				return .Ok;
			}
			else if (tryEat!(TokenType.Dot))
			{
				if (tryEat!(TokenType.LParen)) // .()
				{
					ensureNull!(expr);
					let newOpExpr = new NewOpExpr()
					{
						IsInplace = true,
						TypeSpec = new DotTypeSpec()
					};
					expr = newOpExpr;

					if (!tryEat!(TokenType.RParen))
					{
						newOpExpr.Arguments = new .();
						Parse!(parseCommaSeparatedExprList(ref newOpExpr.Arguments));
						eat!(TokenType.RParen);
					}

					ObjectInitExpr* objectInitExpr = (.)&newOpExpr.Initializer;
					if (!TryParse!(objectInitExpr(ref *objectInitExpr)))
					{
						ArrayInitExpr* arrayInitExpr = (.)&newOpExpr.Initializer;
						TryParse!(arrayInitExpr(ref *arrayInitExpr));
					}
				}
				else
				{
					ensureNull!(expr);
					let memberExpr = new MemberExpr();
					expr = memberExpr;

					Parse!(unaryExpr(ref memberExpr.Right));
				}
				return .Ok;
			}
			else if (tryEat!(TokenType.DotDot))
			{
				ensureNull!(expr);
				let cascadeOpExpr = new CascadeOpExpr();
				expr = cascadeOpExpr;

				Parse!(unaryExpr(ref cascadeOpExpr.Right));
				return .Ok;
			}
			
			TryParse!(postFixExpr(ref expr));
			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> multiplicativeExpr(ref Expression expr)
		{
			TryParse!(unaryExpr(ref expr));
			
			if (expr == null)
				return .NotSuitable;

			while (tryEat!(TokenType.Mul) ||
			       tryEat!(TokenType.Div) ||
				   tryEat!(TokenType.Module))
			{
				let binaryOpExpr = new BinaryOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = binaryOpExpr;

				Parse!(unaryExpr(ref binaryOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> additiveExpr(ref Expression expr)
		{
			TryParse!(multiplicativeExpr(ref expr));
			
			if (expr == null)
				return .NotSuitable;

			while (tryEat!(TokenType.Plus) ||
			       tryEat!(TokenType.Minus))
			{
				let binaryOpExpr = new BinaryOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = binaryOpExpr;

				Parse!(multiplicativeExpr(ref binaryOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> bitwiseShiftExpr(ref Expression expr)
		{
			TryParse!(additiveExpr(ref expr));

			if (tryEat!(TokenType.LShift) ||
			    (_nextToken.Type == .RArrow && tryEat!(TokenType.RArrow)))
			{
				if (_lastToken.Type == .RArrow && _currentToken.Type == .RArrow)
					eat!(TokenType.RArrow);

				let bitwiseOpExpr = new BitwiseOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = bitwiseOpExpr;

				Parse!(additiveExpr(ref bitwiseOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> relationalExpr(ref Expression expr)
		{
			TryParse!(bitwiseShiftExpr(ref expr));
			
			if (expr == null)
				return .NotSuitable;

			if (tryEat!(TokenType.RArrow) ||
			    tryEat!(TokenType.GreaterEq) ||
				tryEat!(TokenType.LArrow) ||
				tryEat!(TokenType.LesserEq) ||
				tryEat!(TokenType.Spaceship) ||
				tryEat!(TokenType.Is) ||
				tryEat!(TokenType.As) ||
				tryEat!(TokenType.Case))
			{
				let comparisonOpExpr = new ComparisonOpExpr()
				{
					Type = _lastToken.Type,
					Left = expr,
				};
				expr = comparisonOpExpr;

				Parse!(bitwiseShiftExpr(ref comparisonOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> equalityExpr(ref Expression expr)
		{
			TryParse!(relationalExpr(ref expr));
			
			if (expr == null)
				return .NotSuitable;

			if (tryEat!(TokenType.Equal) || tryEat!(TokenType.StrictEqual) || tryEat!(TokenType.NotEqual))
			{
				let comparisonOpExpr = new ComparisonOpExpr()
				{
					Type = _lastToken.Type,
					Left = expr,
				};
				expr = comparisonOpExpr;

				Parse!(relationalExpr(ref comparisonOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> bitwiseAndExpr(ref Expression expr)
		{
			TryParse!(equalityExpr(ref expr));

			if (expr == null)
				return .NotSuitable;

			while (tryEat!(TokenType.BitwiseAnd))
			{
				let bitwiseOpExpr = new BitwiseOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = bitwiseOpExpr;

				Parse!(equalityExpr(ref bitwiseOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> bitwiseXorExpr(ref Expression expr)
		{
			TryParse!(bitwiseAndExpr(ref expr));

			if (expr == null)
				return .NotSuitable;

			while (tryEat!(TokenType.BitwiseXor))
			{
				let bitwiseOpExpr = new BitwiseOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = bitwiseOpExpr;

				Parse!(bitwiseAndExpr(ref bitwiseOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> bitwiseOrExpr(ref Expression expr)
		{
			TryParse!(bitwiseXorExpr(ref expr));

			if (expr == null)
				return .NotSuitable;

			while (tryEat!(TokenType.BitwiseOr))
			{
				let bitwiseOpExpr = new BitwiseOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = bitwiseOpExpr;

				Parse!(bitwiseXorExpr(ref bitwiseOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> logicalAndExpr(ref Expression expr)
		{
			TryParse!(bitwiseOrExpr(ref expr));

			if (expr == null)
				return .NotSuitable;

			while (tryEat!(TokenType.And))
			{
				let logicalOpExpr = new LogicalOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = logicalOpExpr;

				Parse!(bitwiseOrExpr(ref logicalOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> logicalOrExpr(ref Expression expr)
		{
			TryParse!(logicalAndExpr(ref expr));
			
			if (expr == null)
				return .NotSuitable;

			while (tryEat!(TokenType.Or))
			{
				let logicalOpExpr = new LogicalOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = logicalOpExpr;

				Parse!(logicalAndExpr(ref logicalOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> coalescenseOperator(ref Expression expr)
		{
			TryParse!(logicalOrExpr(ref expr));
			
			if (expr == null)
				return .NotSuitable;

			if (tryEat!(TokenType.NullCoarl))
			{
				let nullCondOpExpr = new NullCondOpExpr()
				{
					Expr = expr
				};
				expr = nullCondOpExpr;

				Parse!(expression(ref nullCondOpExpr.NullExpr));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> condOperator(ref Expression expr)
		{
			TryParse!(coalescenseOperator(ref expr));
			
			if (expr == null)
				return .NotSuitable;

			if (tryEat!(TokenType.QuestionMark))
			{
				let condOpExpr = new CondOpExpr()
				{
					Expr = expr
				};
				expr = condOpExpr;

				Parse!(expression(ref condOpExpr.TrueExpr));
				eat!(TokenType.Colon);
				Parse!(expression(ref condOpExpr.FalseExpr));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> expression(ref Expression expr)
		{
			TryParse!(condOperator(ref expr));
			
			if (expr == null)
				return .NotSuitable;

			if (tryEat!(TokenType.Assign))
			{
				let assignExpr = new AssignExpr()
				{
					Left = expr
				};
				expr = assignExpr;

				scope TemporaryChange<ContextScopeType>(ref _context.ScopeType, .Assignment);

				Parse!(expression(ref assignExpr.Right));
			}
			else if (tryEat!(TokenType.AddAssign) ||
					 tryEat!(TokenType.SubAssign) ||
					 tryEat!(TokenType.MulAssign) ||
					 tryEat!(TokenType.DivAssign) ||
					 tryEat!(TokenType.ModAssign) ||
					 tryEat!(TokenType.RShiftAssign) ||
					 tryEat!(TokenType.LShiftAssign) ||
					 tryEat!(TokenType.BitAndAssign) ||
					 tryEat!(TokenType.BitXorAssign) ||
					 tryEat!(TokenType.BitOrAssign))
			{
				let compAssignOpExpr = new CompoundAssignOpExpr()
				{
					Left = expr,
					Operation = _lastToken.Type
				};
				expr = compAssignOpExpr;

				Parse!(expression(ref compAssignOpExpr.Right));
			}

			return expr == null ? .NotSuitable : .Ok;
		}

		private ParseResult<void> labeledStmt(ref Statement stmt, bool needSemi)
		{
			if (_currentToken.Type == .Identifier && _nextToken.Type == .Colon)
			{
				eat!(TokenType.Identifier);

				let lblStmt = new LabeledStmt()
				{
					Label = _lastToken.AsText()
				};
				stmt = lblStmt;

				eat!(TokenType.Colon);

				Parse!(statement(ref lblStmt.Statement, needSemi));

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> returnStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Return))
			{
				let retStmt = new ReturnStmt();
				stmt = retStmt;

				if (_currentToken.Type != .Semi)
					Parse!(expression(ref retStmt.Expr));

				eat!(TokenType.Semi);

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> continueStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Continue))
			{
				StringView targetLabel = default;
				if (_currentToken.Type != .Semi)
				{
					eat!(TokenType.Identifier);
					targetLabel = _lastToken.AsText();
				}
				eat!(TokenType.Semi);
				stmt = new ContinueStmt()
				{
					TargetLabel = targetLabel
				};
				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> breakStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Break))
			{
				StringView targetLabel = default;
				if (_currentToken.Type != .Semi)
				{
					eat!(TokenType.Identifier);
					targetLabel = _lastToken.AsText();
				}
				eat!(TokenType.Semi);
				stmt = new BreakStmt()
				{
					TargetLabel = targetLabel
				};
				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> fallthroughStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Fallthrough))
			{
				eat!(TokenType.Semi);
				stmt = new FallthroughStmt();
				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> forStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.For) || tryEat!(TokenType.Foreach))
			{
				eat!(TokenType.LParen);

				ensureNull!(stmt);
				ForStmt forStmt = null;

				if (!tryEat!(TokenType.Semi))
				{
					VariableDecl declaration = null;
					if (!TryParse!(variableDecl(ref declaration)))
					{
						let tokenIndexBkp = _tokenIndex;
						if (TryParse!(checkTypeSpec()))
						{
							eat!(TokenType.Identifier);

							if (_currentToken.Type != .In && _currentToken.Type != .Semi)
							{
								// for ({var} < {number})

								// Rollback to before the TypeSpec
								_tokenIndex = tokenIndexBkp;
								
								forStmt = new ForStmt()
								{
									IsShortForm = true
								};
								stmt = forStmt;

								let varDecl = forStmt.Declaration = new VariableDecl();
								Parse!(typeSpec(ref varDecl.Specification));
								
								eat!(TokenType.Identifier);
								let varName = _lastToken.AsText();

								varDecl.Variables.Add(new VariableDeclarator()
								{
									Name = varName,
									Initializer = new DefaultOpExpr()
								});

								eat!(_currentToken.Type);
								let binaryOpExpr = new BinaryOpExpr()
								{
									Left = new IdentifierExpr(varName),
									Operation = _lastToken.Type
								};
								forStmt.Condition = binaryOpExpr;

								Parse!(expression(ref binaryOpExpr.Right));

								forStmt.Incrementors = new .();
								forStmt.Incrementors.Add(new UnaryOpExpr()
								{
									Operation = .Increment,
									Right = new IdentifierExpr(varName)
								});

								eat!(TokenType.RParen);
	
								Parse!(statement(ref forStmt.Body, true));

								return .Ok;
							}

							// Rollback to before the TypeSpec
							_tokenIndex = tokenIndexBkp;
							
							let foreachStmt = new ForeachStmt();
							stmt = foreachStmt;

							Parse!(typeSpec(ref foreachStmt.TargetType));

							eat!(TokenType.Identifier);
							foreachStmt.TargetName = _lastToken.AsText();
							
							// for ({var} in {enumerable})
							eat!(TokenType.In);

							Parse!(expression(ref foreachStmt.SourceExpr));

							eat!(TokenType.RParen);

							Parse!(statement(ref foreachStmt.Body, true));

							return .Ok;
						}

						forStmt = new ForStmt();
						stmt = forStmt;

						forStmt.Initializers = new .();

						repeat
						{
							// We do this to make sure even the errored Expression gets deleted with the parent node.
							Expression* initExpr = forStmt.Initializers.GrowUninitialized(1);
							*initExpr = null;
							Parse!(expression(ref *initExpr));
						} while (tryEat!(TokenType.Comma));
					}
					else
					{
						// for ({decl}; {comp}; {inc})
						forStmt = new ForStmt()
						{
							Declaration = declaration
						};
						stmt = forStmt;
					}
	
					eat!(TokenType.Semi);
				}
				else
				{
					forStmt = new ForStmt();
					stmt = forStmt;
				}

				if (!tryEat!(TokenType.Semi))
				{
					Parse!(expression(ref forStmt.Condition));
					eat!(TokenType.Semi);
				}

				if (!tryEat!(TokenType.RParen))
				{
					forStmt.Incrementors = new .();

					repeat
					{
						// We do this to make sure even the errored Expression gets deleted with the parent node.
						Expression* incExpr = forStmt.Incrementors.GrowUninitialized(1);
						*incExpr = null;
						Parse!(expression(ref *incExpr));
					} while (tryEat!(TokenType.Comma));
	
					eat!(TokenType.RParen);
				}

				if (!tryEat!(TokenType.Semi))
				{
					Parse!(statement(ref forStmt.Body, true));
				}

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> whileStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.While))
			{
				eat!(TokenType.LParen);

				let whileStmt = new WhileStmt();
				stmt = whileStmt;

				Parse!(expression(ref whileStmt.Condition));

				eat!(TokenType.RParen);

				Parse!(statement(ref whileStmt.Body, true));

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> repeatStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Repeat))
			{
				let repeatStmt = new RepeatStmt();
				stmt = repeatStmt;

				Parse!(statement(ref repeatStmt.Body, true));

				eat!(TokenType.While);

				eat!(TokenType.LParen);

				Parse!(expression(ref repeatStmt.Condition));

				eat!(TokenType.RParen);

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> doStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Do))
			{
				let doStmt = new DoStmt();
				stmt = doStmt;

				Parse!(statement(ref doStmt.Body, false));

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> ifStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.If))
			{
				eat!(TokenType.LParen);

				let ifStmt = new IfStmt();
				stmt = ifStmt;

				Parse!(expression(ref ifStmt.Condition));

				eat!(TokenType.RParen);

				Parse!(statement(ref ifStmt.ThenStatement, true));

				if (tryEat!(TokenType.Else))
					Parse!(statement(ref ifStmt.ElseStatement, true));

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> deferStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Defer))
			{
				let deferStmt = new DeferStmt();
				stmt = deferStmt;

				if (tryEat!(TokenType.Colon))
				{
					eat!(TokenType.Mixin);
					deferStmt.Bind = .Mixin;
				}
				else if (tryEat!(TokenType.DoubleColon))
				{
					deferStmt.Bind = .RootScope;
				}

				Parse!(statement(ref deferStmt.Body, true));

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> usingStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Using))
			{
				eat!(TokenType.LParen);

				let usingStmt = new UsingStmt();
				stmt = usingStmt;

				if (!TryParse!(variableDecl(ref usingStmt.Decl)))
				{
					Parse!(expression(ref usingStmt.Expr));
				}

				eat!(TokenType.RParen);

				Parse!(statement(ref usingStmt.Body, true));

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> switchStmt(ref Statement stmt)
		{
			if (tryEat!(TokenType.Switch))
			{
				eat!(TokenType.LParen);
				
				let switchStmt = new SwitchStmt();
				stmt = switchStmt;

				Parse!(expression(ref switchStmt.Expr));

				eat!(TokenType.RParen);

				eat!(TokenType.LCurly);

				while (tryEat!(TokenType.Case) || tryEat!(TokenType.Default))
				{
					let section = new SwitchSection();

					if (_lastToken.Type != .Default)
					{
						switchStmt.Sections.Add(section);

						repeat
						{
							Expression expr = null;
							Parse!(expression(ref expr));
							section.Labels.Add(expr);
						}
						while (tryEat!(TokenType.Comma));
	
						if (tryEat!(TokenType.When))
							Parse!(expression(ref section.WhenExpr));
					}
					else
					{
						switchStmt.DefaultSection = section;
					}
	
					eat!(TokenType.Colon);

					if (_currentToken.Type == .Case || _currentToken.Type == .Default || _currentToken.Type == .RCurly)
						continue;

					Statement* bodyStmt = ?;
					repeat
					{
						// We do this to make sure even the errored Statement gets deleted with the parent node.
						bodyStmt = section.Statements.GrowUninitialized(1);
						*bodyStmt = null;
					}
					while (TryParse!(statement(ref *bodyStmt, true)));

					// The last one will always be a failed attempt.
					section.Statements.PopBack();
				}
				
				eat!(TokenType.RCurly);

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> declarationStmt(ref Statement stmt, bool needSemi)
		{
			ScopedValueRollback<int> rollback = scope .(ref _tokenIndex);

			defer
			{
				if (!rollback.Cancelled)
					_lastFailureIndex = _tokenIndex;
			}

			bool isConst = tryEat!(TokenType.Const);

			let tokenIndexBkp = _tokenIndex;

			// Little optimization to avoid unnecessary TypeSpec allocations
			if (!TryParse!(checkTypeSpec()))
				return .NotSuitable;

			// Now we can make sure that we are really dealing with a variable
			// <LEVEL> <MODIFIERS> <TYPE> <NAME> <SEMI>/<ASSIGN>/<COMMA>
			if (_nextToken.Type == .Semi || _nextToken.Type == .Assign || _nextToken.Type == .Comma)
			{
				if (_currentToken.Type != .Identifier)
					return .NotSuitable;

				rollback.Cancel();

				// Rollback to before the TypeSpec
				_tokenIndex = tokenIndexBkp;

				TypeSpec typeSpec = null;
				Parse!(typeSpec(ref typeSpec));
				
				let declStmt = new DeclarationStmt()
				{
					IsConst = isConst,
					Declaration = new VariableDecl()
					{
						Specification = typeSpec
					}
				};
				stmt = declStmt;

				let varDecl = declStmt.Declaration;

				repeat
				{
					eat!(TokenType.Identifier);

					let declarator = new VariableDeclarator()
					{
						Name = _lastToken.AsText()
					};
					varDecl.Variables.Add(declarator);
	
					if (tryEat!(TokenType.Assign))
					{
						scope TemporaryChange<ContextScopeType>(ref _context.ScopeType, .Assignment);

						Parse!(expression(ref declarator.Initializer));
					}
				}
				while (tryEat!(TokenType.Comma));

				if (needSemi)
					eat!(TokenType.Semi);

				// TODO
				return .Ok;
			}

			return .NotSuitable;
		}

		// I don't really think that this will ever return .NotSuitable, maybe I should fix this later...
		private ParseResult<void> expressionStmt(ref Statement stmt, bool needSemi)
		{
			Expression expr = null;
			switch (expression(ref expr))
			{
			case .Ok:
				// Is this the right way to do it...?
				let isMixinReturn = _context.Method?.IsMixin == true && _currentToken.Type == .RCurly;
				if (!isMixinReturn)
				{
					if (!isExprValidStatement(expr))
					{
						delete expr;
						raiseError!(_lastToken.Position, "Only assignment, call, increment, decrement, await, and new/delete object expressions can be used as a statement");
					}
	
					if (needSemi && !tryEat!(TokenType.Semi))
					{
						delete expr;
						raiseErrorF!(_currentToken.Position, "Expected \"Semi\" got \"{}\"", _currentToken.Type);
					}
				}

				stmt = new ExpressionStmt()
				{
					Expr = expr
				};
				return .Ok;
			case .NotSuitable:
				delete expr;
				return .NotSuitable;
			case .Err:
				delete expr;
				raiseErrorF!(_currentToken.Position, "Unexpected token '{}'", _currentToken.Type);
			}
		}

		private ParseResult<void> attributedStmt(ref Statement stmt, bool needSemi)
		{
			if (_currentToken.Type == .LBracket)
			{
				let attributedStmt = new AttributedStmt();
				stmt = attributedStmt;

				while (TryParse!(parseAttributes(ref attributedStmt.Attributes))) { }

				Parse!(statement(ref attributedStmt.Statement, needSemi));

				return .Ok;
			}

			return .NotSuitable;
		}

		private ParseResult<void> statement(ref Statement stmt, bool needSemi)
		{
			if (needSemi && tryEat!(TokenType.Semi))
			{
				stmt = new EmptyStmt();
				return .Ok;
			}

			TryParseReturn!(compoundStatement(ref stmt));
			TryParseReturn!(attributedStmt(ref stmt, needSemi));
			TryParseReturn!(labeledStmt(ref stmt, needSemi));
			TryParseReturn!(returnStmt(ref stmt));
			TryParseReturn!(continueStmt(ref stmt));
			TryParseReturn!(breakStmt(ref stmt));
			TryParseReturn!(fallthroughStmt(ref stmt));
			TryParseReturn!(forStmt(ref stmt));
			TryParseReturn!(whileStmt(ref stmt));
			TryParseReturn!(repeatStmt(ref stmt));
			TryParseReturn!(doStmt(ref stmt));
			TryParseReturn!(ifStmt(ref stmt));
			TryParseReturn!(deferStmt(ref stmt));
			TryParseReturn!(usingStmt(ref stmt));
			TryParseReturn!(switchStmt(ref stmt));
			TryParseReturn!(declarationStmt(ref stmt, needSemi));
			TryParseReturn!(expressionStmt(ref stmt, needSemi));

			return .NotSuitable;
		}

		private bool isExprValidStatement(Expression expr)
		{
			switch (expr.GetType())
			{
			case typeof(AssignExpr), typeof(CompoundAssignOpExpr), typeof(CallOpExpr), typeof(NewOpExpr), typeof(DeleteOpExpr), typeof(NewArrayOpExpr):
				return true;
			case typeof(PostfixOpExpr):
				let postfixOpExpr = (PostfixOpExpr)expr;
				return postfixOpExpr.Operation == .Increment ||
					   postfixOpExpr.Operation == .Decrement;
			case typeof(UnaryOpExpr):
				let postfixOpExpr = (UnaryOpExpr)expr;
				return postfixOpExpr.Operation == .Increment ||
					   postfixOpExpr.Operation == .Decrement;
			default:
				return false;
			}
		}

		private ParseResult<void> compoundStatement(ref Statement compound)
		{
			if (tryEat!(TokenType.LCurly))
			{
				let compundStmt = new CompoundStmt();
				compound = compundStmt;

				while (!tryEat!(TokenType.RCurly))
				{
					if (tryEat!(TokenType.Semi))
						continue;

					// We do this to make sure even the errored Statement gets deleted with the parent node.
					Statement* stmt = compundStmt.Statements.GrowUninitialized(1);
					*stmt = null;
					Parse!(statement(ref *stmt, true));
				}

				return .Ok;
			}

			return .NotSuitable;
		}
	}
}
