using System;
using System.Collections;
using BeefParser.AST;

namespace BeefParser.Tests;

static class TestParserRegression
{
	[Test]
	public static void ParsesSimpleAndGenericEnums()
	{
		let parser = scope BeefParser("""
			enum Flags : uint8 { None, First = 1, Second = 2 }
			enum Result<T> : IDisposable where T : struct, IHashable
			{
				case Ok(T value);
				case Err;
			}
			enum Pair<T, U> where T : operator T + T where U : class
			{
				case Value(T first, U second), Empty;
			}
			""");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		let flags = (EnumDecl)root.Declarations[0];
		Test.Assert(flags.IsSimpleEnum);
		Test.Assert(flags.Members.Count == 3);
		Test.Assert(flags.Inheritance.Count == 1);
		let result = (EnumDecl)root.Declarations[1];
		Test.Assert(!result.IsSimpleEnum);
		Test.Assert(result.GenericParametersNames[0] == "T");
		Test.Assert(result.Inheritance.Count == 1);
		Test.Assert(result.Declarations.Count == 2);
		Test.Assert(result.GenericConstraints.Count == 1);
		Test.Assert(result.GenericConstraints[0].Constraints.Count == 2);

		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("enum Result<T> : IDisposable"));
		Test.Assert(code.Contains("where T : struct, IHashable"));
		Test.Assert(!flags.ToString(.. scope .()).Contains(",\n}"));
		let formattedParser = scope BeefParser(code);
		Test.Assert(formattedParser.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;

		let formattedFlags = (EnumDecl)formattedRoot.Declarations[0];
		Test.Assert(formattedFlags.Members.Count == flags.Members.Count);
		let formattedResult = (EnumDecl)formattedRoot.Declarations[1];
		Test.Assert(formattedResult.GenericParametersNames[0] == "T");
		Test.Assert(formattedResult.Inheritance[0].ToString(.. scope .()) == "IDisposable");
		Test.Assert(formattedResult.Declarations.Count == result.Declarations.Count);
		let okCase = ((EnumCaseDecl)formattedResult.Declarations[0]).Items[0];
		Test.Assert(okCase.Name == "Ok");
		Test.Assert(okCase.Parameters[0].Specification.ToString(.. scope .()) == "T");
		Test.Assert(okCase.Parameters[0].Name == "value");
		Test.Assert(((EnumCaseDecl)formattedResult.Declarations[1]).Items[0].Name == "Err");
		Test.Assert(formattedResult.GenericConstraints[0].Target == "T");
		Test.Assert(formattedResult.GenericConstraints[0].Constraints[0] is StructConstraint);
		Test.Assert(((TypeConstraint)formattedResult.GenericConstraints[0].Constraints[1]).TypeSpec.ToString(.. scope .()) == "IHashable");

		let formattedPair = (EnumDecl)formattedRoot.Declarations[2];
		Test.Assert(formattedPair.GenericParametersNames.Count == 2);
		Test.Assert(formattedPair.GenericParametersNames[1] == "U");
		Test.Assert(formattedPair.GenericConstraints.Count == 2);
		let binaryConstraint = (TypeBinaryOpConstraint)formattedPair.GenericConstraints[0].Constraints[0];
		Test.Assert(binaryConstraint.Operation == .Plus);
		Test.Assert(binaryConstraint.Left.ToString(.. scope .()) == "T");
		Test.Assert(binaryConstraint.Right.ToString(.. scope .()) == "T");
		Test.Assert(formattedPair.GenericConstraints[1].Target == "U");
		Test.Assert(formattedPair.GenericConstraints[1].Constraints[0] is ClassConstraint);
		let pairCases = (EnumCaseDecl)formattedPair.Declarations[0];
		Test.Assert(pairCases.Items.Count == 2);
		Test.Assert(pairCases.Items[0].Parameters.Count == 2);
		Test.Assert(pairCases.Items[1].Name == "Empty");
	}

	[Test]
	public static void PreservesPostfixDeleteAllocatorTargets()
	{
		String[?] inputs = .("delete:allocator.Current ptr", "delete:allocators[index] ptr", "delete:allocator.GetCurrent() ptr", "delete:allocator.Current owner.ptr", "delete:allocators[index] pointers[index]");
		for (let input in inputs)
		{
			let parser = scope BeefParser(input);
			Test.Assert(parser.ParseTo(let expr) case .Ok);
			defer delete expr;
			let deletion = (DeleteOpExpr)expr;
			let targetStart = "delete:".Length;
			let operandStart = input.LastIndexOf(' ') + 1;
			Test.Assert(deletion.Target is MemberExpr || deletion.Target is IndexOpExpr || deletion.Target is CallOpExpr);
			Test.Assert(deletion.Target.ToString(.. scope .()) == input.Substring(targetStart, operandStart - targetStart - 1));
			Test.Assert(deletion.Expr.ToString(.. scope .()) == input.Substring(operandStart));

			let formattedParser = scope BeefParser(expr.ToString(.. scope .()));
			Test.Assert(formattedParser.ParseTo(let formattedExpr) case .Ok);
			defer delete formattedExpr;
			let formattedDeletion = (DeleteOpExpr)formattedExpr;
			Test.Assert(formattedDeletion.Target.ToString(.. scope .()) == deletion.Target.ToString(.. scope .()));
			Test.Assert(formattedDeletion.Expr.ToString(.. scope .()) == deletion.Expr.ToString(.. scope .()));
		}
	}

	[Test]
	public static void ParsesAnonymousForeach()
	{
		let parser = scope BeefParser("class Example { void Run() { for (this.Split(separator)) count++; } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		let example = (ClassDecl)root.Declarations[0];
		let method = (MethodDecl)example.Declarations[0];
		let foreachStmt = (ForeachStmt)((CompoundStmt)method.CompoundStmt).Statements[0];
		Test.Assert(foreachStmt.IsAnonymous);
		Test.Assert(foreachStmt.TargetType == null);
		Test.Assert(foreachStmt.TargetName.IsEmpty);
		Test.Assert(foreachStmt.SourceExpr.ToString(.. scope .()) == "this.Split(separator)");
		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("for (this.Split(separator))"));
		let formattedParser = scope BeefParser(code);
		Test.Assert(formattedParser.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
		let formattedMethod = (MethodDecl)((ClassDecl)formattedRoot.Declarations[0]).Declarations[0];
		Test.Assert(((ForeachStmt)((CompoundStmt)formattedMethod.CompoundStmt).Statements[0]).IsAnonymous);
	}

	[Test]
	public static void ParsesMutablePropertyAccessors()
	{
		let parser = scope BeefParser("class Example { int Value { get; set mut; } }");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		let propertyDecl = (PropertyDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		Test.Assert(propertyDecl.Accessors.Count == 2);
		Test.Assert(!propertyDecl.Accessors[0].IsMutable);
		Test.Assert(propertyDecl.Accessors[1].IsMutable);

		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("set mut;"));
		let formattedParser = scope BeefParser(code);
		Test.Assert(formattedParser.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;
		let formattedProperty = (PropertyDecl)((ClassDecl)formattedRoot.Declarations[0]).Declarations[0];
		Test.Assert(formattedProperty.Accessors[1].IsMutable);
	}

	[Test]
	public static void FormatsIndexerAccessorModifiersAndExpressions()
	{
		let parser = scope BeefParser("""
			struct Example
			{
				int this[int index]
				{
					get { return 0; }
					set ref mut => Store(index, value);
				}
			}
			""");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		let example = (StructDecl)root.Declarations[0];
		let indexer = (IndexPropertyDecl)example.Declarations[0];
		let setter = indexer.Accessors[1];
		Test.Assert(setter.IsRef && setter.IsMutable);
		Test.Assert(setter.Expr != null);

		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("set ref mut => Store(index, value);"));
		let formattedParser = scope BeefParser(code);
		Test.Assert(formattedParser.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;

		let formattedIndexer = (IndexPropertyDecl)((StructDecl)formattedRoot.Declarations[0]).Declarations[0];
		let formattedSetter = formattedIndexer.Accessors[1];
		Test.Assert(formattedSetter.IsRef && formattedSetter.IsMutable);
		Test.Assert(formattedSetter.Expr != null);
	}

	[Test]
	public static void PreservesExpressionBodiesAndOperatorTokens()
	{
		let parser = scope BeefParser("""
			class Example
			{
				void Run() => Work();
				Nothing Work() => Run();
				this() => Run();
				static bool operator==(Example lhs, Example rhs) => true;
				static Example operator>>(Example lhs, int count) => lhs;
				static operator StringView(Example value) => default;
				T Identity<T>(T value) where T : IHashable => value;
				void Accept(Object object, int64 int) => Work();
				static implicit operator Span<char8>(Example value) => default;
				static explicit operator Example(StringView value) => default;
			}
			""");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		let example = (ClassDecl)root.Declarations[0];
		for (let declaration in example.Declarations)
		{
			let method = (MethodDecl)declaration;
			Test.Assert(method.Body is Expression);
			Test.Assert(method.CompoundStmt == null);
		}
		Test.Assert(((MethodDecl)example.Declarations[3]).OperatorToken == TokenType.Equal);
		Test.Assert(((MethodDecl)example.Declarations[4]).OperatorToken == TokenType.RShift);
		Test.Assert(((MethodDecl)example.Declarations[5]).OperatorType == .None);
		Test.Assert(!((MethodDecl)example.Declarations[5]).OperatorToken.HasValue);
		Test.Assert(((MethodDecl)example.Declarations[8]).OperatorType == .Implicit);
		Test.Assert(((MethodDecl)example.Declarations[9]).OperatorType == .Explicit);

		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("Nothing Work() => Run();"));
		Test.Assert(code.Contains("this() => Run();"));
		Test.Assert(code.Contains("bool operator==(Example lhs, Example rhs) => true;"));
		Test.Assert(code.Contains("Example operator>>(Example lhs, int count) => lhs;"));
		Test.Assert(code.Contains("operator StringView(Example value) => default;"));
		Test.Assert(code.Contains("Accept(Object object, int64 int)"));
		Test.Assert(code.Contains("implicit operator Span<char8>(Example value)"));
		Test.Assert(code.Contains("explicit operator Example(StringView value)"));
		let formattedParser = scope BeefParser(code);
		Test.Assert(formattedParser.Parse(let formattedRoot) case .Ok);
		defer delete formattedRoot;

		List<Statement> statements = scope .();
		defer { Release!(statements, ContainerReleaseKind.Items); }
		let localParser = scope BeefParser("int Local() => 1;");
		Test.Assert(localParser.ParseTo(statements) case .Ok);
		let localMethod = ((LocalMethodStmt)statements[0]).MethodDeclaration;
		Test.Assert(localMethod.Body is IntLiteral);
		Test.Assert(localMethod.CompoundStmt == null);
	}

	[Test]
	public static void PreservesParamsAndAllocatorExpressions()
	{
		let parser = scope BeefParser("""
			class Example
			{
				void Run(params Object[] values)
				{
					Forward(params values);
					new Example(params values);
					char8* ptr = new:this char8[count]*;
					delete:this ptr;
					delete:(GetAllocator()) ptr;
				}
			}
			""");
		Test.Assert(parser.Parse(let root) case .Ok);
		defer delete root;

		let method = (MethodDecl)((ClassDecl)root.Declarations[0]).Declarations[0];
		Test.Assert(method.FormalParameters[0].IsParams);
		let body = (CompoundStmt)method.CompoundStmt;
		let call = (CallOpExpr)((ExpressionStmt)body.Statements[0]).Expr;
		Test.Assert(call.Params[0] is ParamsExpr);
		let allocation = (NewOpExpr)((ExpressionStmt)body.Statements[1]).Expr;
		Test.Assert(allocation.Arguments[0] is ParamsExpr);
		let array = (NewArrayOpExpr)((DeclarationStmt)body.Statements[2]).Declaration.Variables[0].Initializer;
		Test.Assert(array.IsRawAllocation);
		Test.Assert(array.TypeSpec.Element is IdentifierName);

		let code = root.ToString(.. scope .());
		Test.Assert(code.Contains("Forward(params values);"));
		Test.Assert(code.Contains("new Example(params values)"));
		Test.Assert(code.Contains("new:this char8[count]*"));
		Test.Assert(code.Contains("delete:this ptr;"));
		Test.Assert(code.Contains("delete:(GetAllocator()) ptr;"));
	}

	[Test]
	public static void DistinguishesRawArrayAllocationFromPointerElements()
	{
		String[?] inputs = .("new char8[count]", "new char8[count]*", "new char8*[count]", "new char8*[count]*");
		bool[?] rawAllocations = .(false, true, false, true);
		bool[?] pointerElements = .(false, false, true, true);
		for (int i = 0; i < inputs.Count; i++)
		{
			let parser = scope BeefParser(inputs[i]);
			Test.Assert(parser.ParseTo(let expr) case .Ok);
			defer delete expr;
			let array = (NewArrayOpExpr)expr;
			Test.Assert(array.IsRawAllocation == rawAllocations[i]);
			Test.Assert((array.TypeSpec.Element is PointerTypeSpec) == pointerElements[i]);
			Test.Assert(expr.ToString(.. scope .()) == inputs[i]);
		}
	}

	[Test]
	public static void DecodesCharacterLiterals()
	{
		String[?] literals = .(@"'\x00'", @"'\n'", "'é'", "'😀'", @"'\u{1F600}'", @"'\''", @"'\\'");
		char32[?] expected = .('\0', '\n', 'é', '😀', '😀', '\'', '\\');
		for (int i = 0; i < literals.Count; i++)
		{
			let parser = scope BeefParser(literals[i]);
			Test.Assert(parser.ParseTo(let expr) case .Ok);
			defer delete expr;
			Test.Assert(((CharLiteral)expr).Value == expected[i]);

			let formattedParser = scope BeefParser(expr.ToString(.. scope .()));
			Test.Assert(formattedParser.ParseTo(let formattedExpr) case .Ok);
			defer delete formattedExpr;
			Test.Assert(((CharLiteral)formattedExpr).Value == expected[i]);
		}

		String[?] invalidLiterals = .("''", "'''", "'ab'", @"'\x0'", @"'\u{}'", @"'\u{110000}'", @"'\u{D800}'");
		for (let literal in invalidLiterals)
		{
			let lexer = scope Lexer(literal);
			Test.Assert(lexer.GetNextToken() case .Err);
		}
	}
}
