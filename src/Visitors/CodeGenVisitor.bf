using System;
using System.Collections;
using System.Diagnostics;

using internal BeefParser;

namespace BeefParser.AST;

public class CodeGenVisitor : ASTVisitor
{
	private String mOutput;
	private int mIdentation = 0;
	private MethodDecl mCurMethod;

	public String Output
	{
		get => mOutput;
		set => mOutput = value;
	}

	public this(String output)
	{
		mOutput = output;
	}

	public mixin Write(var str, bool ident = false)
	{
		if (ident)
			mOutput.Append('\t', mIdentation);
		mOutput.Append(str);
	}

	public mixin BreakLine()
	{
		mOutput.Append('\n');
	}

	public mixin WriteLine(var str, bool ident = false)
	{
		if (ident)
			mOutput.Append('\t', mIdentation);
		mOutput.Append(str);
		mOutput.Append('\n');
	}

	public static mixin EnumToLowerString(var e)
	{
		String str = scope:mixin .();
		e.ToString(str);
		str.ToLower();
		str
	}

	public static mixin FlagsToLowerSeparatedString<T>(T e, StringView sep) where T : var
	{
		String str = scope:mixin .();
		for (let field in typeof(T).GetFields())
		{
			let fieldData = field.[Friend]mFieldData;
			if (fieldData.mData == 0 || !e.HasFlag((T)fieldData.mData))
				continue;

			str.Append(EnumToLowerString!((T)fieldData.mData));
			str.Append(sep);
		}

		str
	}

	public static mixin EnumToAnotherEnum<From, To>(From e) where From : var where To : var
	{
		To newEnum = default;
		for (let field in typeof(To).GetFields())
		{
			let fieldData = field.[Friend]mFieldData;
			newEnum = (To)fieldData.mData;
			if (EnumToLowerString!(e) == EnumToLowerString!(newEnum))
				break;
		}

		newEnum
	}

	/// This will discard the VisitResult!
	public new void Visit(ASTNode node)
	{
		node.Accept(this);
	}

	public override VisitResult Visit(CompilationUnit compilationUnit)
	{
		for (let usingDir in compilationUnit.Usings)
		{
			Visit(usingDir);
		}
		if (!compilationUnit.Usings.IsEmpty)
			BreakLine!();

		for (let decl in compilationUnit.Declarations)
		{
			Visit(decl);
			if (@decl.Index < compilationUnit.Declarations.Count - 1)
				BreakLine!();
		}
		return .Continue;
	}
	
	public override VisitResult Visit(NamespaceDecl nsDecl)
	{
		Write!("namespace ", true);
		Write!(nsDecl.Name);
		BreakLine!();
		WriteLine!("{", true);

		outer: {
			scope:outer TemporaryChange<int>(ref mIdentation, mIdentation + 1);

			for (var decl in nsDecl.Declarations)
			{
				Visit(decl);
				if (@decl.Index < nsDecl.Declarations.Count - 1)
					BreakLine!();
			}
		}

		WriteLine!("}", true);

		return .Continue;
	}
	
	public override VisitResult Visit(UsingDirective usingDecl)
	{
		Write!("using ", true);
		if (usingDecl.isInternal) Write!("internal ");
		else if (usingDecl.isStatic) Write!("static ");
		Write!(usingDecl.Name);
		WriteLine!(";");
		return .Continue;
	}

	public override VisitResult Visit(TypeAliasDecl typeAliasDecl)
	{
		Write!("typealias ", true);
		Write!(typeAliasDecl.Name);
		if (!typeAliasDecl.GenericParametersNames.IsEmpty)
		{
			Write!("<");
			for (var param in typeAliasDecl.GenericParametersNames)
			{
				Write!(param);
				if (@param.Index != typeAliasDecl.GenericParametersNames.Count - 1)
					Write!(", ");
			}
			Write!(">");
		}
		Write!(" = ");
		Visit(typeAliasDecl.TypeSpec);
		WriteLine!(";");
		return .Continue;
	}

	public override VisitResult Visit(FieldDecl fieldDecl)
	{
		if (mCurMethod == null)
		{
			if (!fieldDecl.Attributes.IsEmpty)
			{
				Write!("", true);
				WriteAttributes(fieldDecl.Attributes);
				BreakLine!();
			}

			Write!("", true);
		}
		else
		{
			Debug.Assert(fieldDecl.Attributes?.IsEmpty ?? true);
		}

		WriteAccessLevel(fieldDecl.AccessLevel);
		WriteModifiers(fieldDecl.Modifiers);

		Visit(fieldDecl.Declaration);
		return .Continue;
	}

	public override VisitResult Visit(PropertyDecl propertyDecl)
	{
		if (!propertyDecl.Attributes.IsEmpty)
		{
			Write!("", true);
			WriteAttributes(propertyDecl.Attributes);
			BreakLine!();
		}

		Write!("", true);

		WriteAccessLevel(propertyDecl.AccessLevel);
		WriteModifiers(propertyDecl.Modifiers);
		
		Visit(propertyDecl.Specification);
		Write!(" ");
		if (propertyDecl.ExplicitInterfaceName != null)
		{
			Visit(propertyDecl.ExplicitInterfaceName);
			Write!(".");
		}
		Write!(propertyDecl.Name);

		if (propertyDecl.Accessors.Count == 1 && propertyDecl.Accessors[0].AccessorType == .Get && propertyDecl.Accessors[0].Expr != null)
		{
			Write!(" => ");
			Visit(propertyDecl.Accessors[0].Expr);
			Write!(";");
		}
		else
		{
			BreakLine!();
			WriteLine!("{", true);

			{
				scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);
	
				for (let accessor in propertyDecl.Accessors)
				{
					if (!accessor.Attributes.IsEmpty)
					{
						Write!("", true);
						WriteAttributes(accessor.Attributes);
						BreakLine!();
					}
	
					Write!("", true);
					WriteAccessLevel(accessor.AccessLevel);
			
					switch (accessor.AccessorType)
					{
					case .Get: Write!("get");
					case .Set: Write!("set");
					}

					if (accessor.Expr != null)
					{
						Write!(" => ");
						Visit(propertyDecl.Accessors[0].Expr);
						Write!(";");
					}
					else if (accessor.Statement != null)
					{
						BreakLine!();
						Visit(accessor.Statement);
					}
					else
					{
						WriteLine!(";");
					}

					if (@accessor.Index != propertyDecl.Accessors.Count - 1)
						BreakLine!();
				}
			}

			Write!("}", true);
		}

		BreakLine!();

		return .Continue;
	}

	public override VisitResult Visit(IndexPropertyDecl indexerDecl)
	{
		if (!indexerDecl.Attributes.IsEmpty)
		{
			Write!("", true);
			WriteAttributes(indexerDecl.Attributes);
			BreakLine!();
		}

		Write!("", true);

		WriteAccessLevel(indexerDecl.AccessLevel);
		WriteModifiers(indexerDecl.Modifiers);
		
		Visit(indexerDecl.Specification);
		Write!(" ");
		if (indexerDecl.ExplicitInterfaceName != null)
		{
			Visit(indexerDecl.ExplicitInterfaceName);
			Write!(".");
		}
		Write!("this[");

		for (let param in indexerDecl.FormalParameters)
		{
			WriteParamDecl(param);
			if (@param.Index < indexerDecl.FormalParameters.Count - 1)
				Write!(", ");
		}
		Write!("]");

		BreakLine!();
		WriteLine!("{", true);

		scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);
		for (let accessor in indexerDecl.Accessors)
		{
			if (!accessor.Attributes.IsEmpty)
			{
				Write!("", true);
				WriteAttributes(accessor.Attributes);
				BreakLine!();
			}
	
			Write!("", true);
			WriteAccessLevel(accessor.AccessLevel);

			switch (accessor.AccessorType)
			{
			case .Get: Write!("get");
			case .Set: Write!("set");
			}

			if (accessor.Expr != null)
			{
				Write!(" => ");
				Visit(indexerDecl.Accessors[0].Expr);
				Write!(";");
			}
			else if (accessor.Statement != null)
			{
				BreakLine!();
				Visit(accessor.Statement);
			}
			else
			{
				WriteLine!(";");
			}

			if (@accessor.Index != indexerDecl.Accessors.Count - 1)
				BreakLine!();
		}

		WriteLine!("}", true);
		BreakLine!();

		return .Continue;
	}
	
	public override VisitResult Visit(VariableDecl varDecl)
	{
		Write!(varDecl.Specification);
		Write!(" ");

		for (let variable in varDecl.Variables)
		{
			Write!(variable.Name);

			if (variable.Initializer != null)
			{
				Write!(" = ");
				Visit(variable.Initializer);
			}
			if (variable.Finalizer != null)
			{
				Write!(" ~ ");
				Visit(variable.Finalizer);
			}

			if (@variable.Index != varDecl.Variables.Count - 1)
				Write!(", ");
		}

		Write!(";");
		return .Continue;
	}
	
	public override VisitResult Visit(ClassDecl classDecl)
	{
		if (!classDecl.Attributes.IsEmpty)
		{
			Write!("", true);
			WriteAttributes(classDecl.Attributes);
			BreakLine!();
		}

		Write!("", true);

		WriteAccessLevel(classDecl.AccessLevel);
		WriteModifiers(classDecl.Modifiers);

		Write!("class ");
		Write!(classDecl.Name);

		if (!classDecl.Inheritance.IsEmpty)
		{
			Write!(" : ");

			for (var inh in classDecl.Inheritance)
			{
				Write!(inh.ToString(.. scope .()));
				if (@inh.Index != classDecl.Inheritance.Count - 1)
					Write!(", ");
			}
		}

		// TODO: Write Generic Parameters
		// TODO: Write Generic Constraints

		BreakLine!();
		WriteLine!("{", true);

		{
			scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);

			for (var decl in classDecl.Declarations)
			{
				Visit(decl);

				if (@decl.Index != classDecl.Declarations.Count - 1 && (decl is BaseTypeDecl || decl is MethodDecl))
					BreakLine!();
			}
		}

		WriteLine!("}", true);
		return .Continue;
	}

	public override VisitResult Visit(StructDecl structDecl)
	{
		if (!structDecl.Attributes.IsEmpty)
		{
			Write!("", true);
			WriteAttributes(structDecl.Attributes);
			BreakLine!();
		}

		Write!("", true);

		WriteAccessLevel(structDecl.AccessLevel);
		WriteModifiers(structDecl.Modifiers);

		Write!("struct ");
		Write!(structDecl.Name);

		if (!structDecl.Inheritance.IsEmpty)
		{
			Write!(" : ");

			for (var inh in structDecl.Inheritance)
			{
				Write!(inh.ToString(.. scope .()));
				if (@inh.Index != structDecl.Inheritance.Count - 1)
					Write!(", ");
			}
		}

		// TODO: Write Generic Parameters
		// TODO: Write Generic Constraints

		BreakLine!();
		WriteLine!("{", true);

		{
			scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);

			for (var decl in structDecl.Declarations)
			{
				Visit(decl);

				if (@decl.Index != structDecl.Declarations.Count - 1 && (decl is BaseTypeDecl || decl is MethodDecl))
					BreakLine!();
			}
		}

		WriteLine!("}", true);
		return .Continue;
	}

	public override VisitResult Visit(EnumDecl enumDecl)
	{
		if (!enumDecl.Attributes.IsEmpty)
		{
			Write!("", true);
			WriteAttributes(enumDecl.Attributes);
			BreakLine!();
		}

		Write!("", true);

		WriteAccessLevel(enumDecl.AccessLevel);
		WriteModifiers(enumDecl.Modifiers);

		Write!("enum ");
		Write!(enumDecl.Name);

		BreakLine!();
		WriteLine!("{", true);

		{
			scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);

			int i = 0;
			for (var decl in enumDecl.Declarations)
			{
				Write!(decl.key, true);

				if (decl.value != null)
				{
					Write!(" = ");
					Visit(decl.value);
				}

				if (++i != enumDecl.Declarations.Count)
				{
					Write!(",");
					BreakLine!();
				}
			}
		}

		BreakLine!();
		WriteLine!("}", true);
		return .Continue;
	}

	public override VisitResult Visit(DelegateDecl delDecl)
	{
		if (!delDecl.Attributes.IsEmpty)
		{
			Write!("", true);
			WriteAttributes(delDecl.Attributes);
			BreakLine!();
		}

		Write!("", true);

		WriteAccessLevel(delDecl.AccessLevel);
		WriteModifiers(delDecl.Modifiers);

		Write!("delegate ");
		Write!(delDecl.Specification);
		Write!(" ");
		Write!(delDecl.Name);

		if (!delDecl.GenericParametersNames.IsEmpty)
		{
			Write!("<");
			for (var param in delDecl.GenericParametersNames)
			{
				Write!(param);
				if (@param.Index != delDecl.GenericParametersNames.Count - 1)
					Write!(", ");
			}
			Write!(">");
		}

		Write!("(");

		for (var param in delDecl.FormalParameters)
		{
			WriteParamDecl(param);
			if (@param.Index != delDecl.FormalParameters.Count - 1)
				Write!(", ");
		}

		Write!(")");

		if (!delDecl.GenericConstraints.IsEmpty)
		{
			Write!(" ");

			mIdentation += 1;
			defer { mIdentation -= 1; }

			for (let constraintDecl in delDecl.GenericConstraints)
			{
				Write!("where ", true);
				Write!(constraintDecl.Target);
				Write!(" : ");
				for (int idx = 0; idx < constraintDecl.Constraints.Count; idx++)
				{
					let paramConstraint = constraintDecl.Constraints[idx];
					switch(paramConstraint.GetType())
					{
					case typeof(TypeConstraint):
						TypeConstraint typeParamConstraint = (TypeConstraint)paramConstraint;
						Write!(typeParamConstraint.TypeSpec.ToString(.. scope .()));
					default:
						Write!(paramConstraint.Text);
					}

					if (idx != constraintDecl.Constraints.Count - 1)
						Write!(", ");
				}
			}
		}

		WriteLine!(";");
		return .Continue;
	}

	public void WriteAccessLevel(AccessLevel level)
	{
		if (level == .Undefined)
			return;

		switch (level)
		{
		case .PrivateProtected:
			Write!("private protected ");
			break;
		case .ProtectedInternal:
			Write!("protected internal ");
			break;
		default:
			Write!(EnumToLowerString!(level));
			Write!(" ");
			break;
		}
	}

	public void WriteModifiers(Modifier modifiers)
	{
		if (modifiers == .None)
			return;
		
		Write!(FlagsToLowerSeparatedString!(modifiers, " "));
	}

	public void WriteParamDecl(ParamDecl paramDecl)
	{
		if (!paramDecl.Attributes.IsEmpty)
		{
			WriteAttributes(paramDecl.Attributes);
			Write!(" ");
		}

		if (paramDecl.IsIn)
			Write!("in ");
		else if (paramDecl.IsOut)
			Write!("out ");
		else if (paramDecl.IsRef)
			Write!("ref ");
		Write!(paramDecl.Specification);

		if (!paramDecl.Name.IsEmpty)
		{
			Write!(" ");
			Write!(paramDecl.Name);

			if (paramDecl.Name == "params") // params is a keyword in beef
				Write!("s");
			if (paramDecl.Name == "ref") // ref is a keyword in beef
				Write!("f");
		}

		if (paramDecl.Default != null)
		{
			Write!(" = ");
			Visit(paramDecl.Default);
		}
	}

	public void WriteAttributes(List<AttributeSpec> attrs)
	{
		if (attrs == null || attrs.IsEmpty)
			return;

		Write!("[");
		for (var attr in attrs)
		{
			if (attr.IsReturn) Write!("return: ");
			else if (attr.IsAssembly) Write!("assembly: ");
			Write!(attr.TypeSpec);

			if (!attr.Arguments.IsEmpty)
			{
				Write!("(");
				for (let param in attr.Arguments)
				{
					Visit(param);

					if (@param.Index < attr.Arguments.Count - 1)
						Write!(", ");
				}
				Write!(")");
			}

			if (@attr.Index < attrs.Count - 1)
				Write!(", ");
		}
		Write!("]");
	}
	
	public override VisitResult Visit(MethodDecl methodDecl)
	{
		if (!methodDecl.Attributes.IsEmpty)
		{
			Write!("", true);
			WriteAttributes(methodDecl.Attributes);
			BreakLine!();
		}

		Write!("", true);

		// Beef has no support for unsafe modifier
		if (methodDecl.Modifiers.HasFlag(.Unsafe))
			methodDecl.Modifiers &= ~.Unsafe;

		WriteAccessLevel(methodDecl.AccessLevel);
		WriteModifiers(methodDecl.Modifiers);

		if (methodDecl.IsMixin)
			Write!("mixin ");

		if (methodDecl.IsOperator)
		{
			Write!(EnumToLowerString!(methodDecl.OperatorType));
			Write!(" operator ");
		}

		if (!methodDecl.IsConstructor && !methodDecl.IsDestructor)
		{
			Write!(methodDecl.Specification);
			if (!methodDecl.IsOperator)
				Write!(" ");
		}

		if (!methodDecl.IsOperator)
		{
			if (methodDecl.IsConstructor)
			{
				Write!(methodDecl.Name);
			}
			else if (methodDecl.IsDestructor)
			{
				Write!("~");
				Write!(methodDecl.Name);
			}
			else
			{
				Write!(methodDecl.Name);
				//Write!(" ");

				// TODO: Write Generic Parameters
				// TODO: Write Generic Constraints
			}
		}

		if (!methodDecl.GenericParametersNames.IsEmpty)
		{
			Write!("<");
			for (var param in methodDecl.GenericParametersNames)
			{
				Write!(param);
				if (@param.Index != methodDecl.GenericParametersNames.Count - 1)
					Write!(", ");
			}
			Write!(">");
		}

		Write!("(");

		for (var param in methodDecl.FormalParameters)
		{
			WriteParamDecl(param);
			if (@param.Index != methodDecl.FormalParameters.Count - 1)
				Write!(", ");
		}

		Write!(")");

		if (methodDecl.IsMutable)
			Write!(" mut");

		if (methodDecl.Modifiers.HasFlag(.Abstract) || methodDecl.Modifiers.HasFlag(.Extern))
		{
			Write!(";");
			BreakLine!();
		}
		else
		{
			BreakLine!();

			if (!methodDecl.GenericConstraints.IsEmpty)
			{
				mIdentation += 1;
				defer { mIdentation -= 1; }

				for (let constraintDecl in methodDecl.GenericConstraints)
				{
					Write!("where ", true);
					Write!(constraintDecl.Target);
					Write!(" : ");
					for (int idx = 0; idx < constraintDecl.Constraints.Count; idx++)
					{
						let paramConstraint = constraintDecl.Constraints[idx];
						switch(paramConstraint.GetType())
						{
						case typeof(TypeConstraint):
							TypeConstraint typeParamConstraint = (TypeConstraint)paramConstraint;
							Write!(typeParamConstraint.TypeSpec.ToString(.. scope .()));
						default:
							Write!(paramConstraint.Text);
						}

						if (idx != constraintDecl.Constraints.Count - 1)
							Write!(", ");
					}
				}

				BreakLine!();
			}
			
			mCurMethod = methodDecl;
			Visit(methodDecl.CompoundStmt);
			mCurMethod = null;
		}

		return .Continue;
	}

	public override VisitResult Visit(NullLiteral nullConstExpr)
	{
		Write!("null");
		return .Continue;
	}
	
	public override VisitResult Visit(BoolLiteral boolConstExpr)
	{
		Write!(boolConstExpr.Value ? "true" : "false");
		return .Continue;
	}
	
	public override VisitResult Visit(IntLiteral numConstExpr)
	{
		// TODO: Handle Type and Kind

		String str = scope .();
		((int64)numConstExpr.Value).ToString(str);

		Write!(str);

		return .Continue;
	}
	
	public override VisitResult Visit(RealLiteral numConstExpr)
	{
		switch(numConstExpr.Type)
		{
		case .Float, .Double:
			String str = scope .();
			numConstExpr.Value.ToString(str);

			Write!(str);
			if (numConstExpr.Type == .Float)
				Write!("f");
			break;
		case .Decimal:
			Runtime.NotImplemented();
		}
		return .Continue;
	}
	
	public override VisitResult Visit(StrLiteral strConstExpr)
	{
		Write!(strConstExpr.Value.QuoteString(.. scope .()));
		return .Continue;
	}
	
	public override VisitResult Visit(CharLiteral chrConstExpr)
	{
		let escapedStr = chrConstExpr.Value.ToString(.. scope .()).Escape(.. scope .());

		Write!("'");
		Write!(escapedStr);
		Write!("'");

		return .Continue;
	}

	public override VisitResult Visit(AttributedStmt node)
	{
		if (!node.Attributes.IsEmpty)
		{
			Write!("", true);
			WriteAttributes(node.Attributes);
			BreakLine!();
		}
		Visit(node.Statement);
		return .Continue;
	}

	public override VisitResult Visit(CompoundStmt compStmt)
	{
		WriteLine!("{", true);
		
		if (!compStmt.Statements.IsEmpty)
		{
			scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);
			
			for (var stmt in compStmt.Statements)
			{
				if (stmt.GetType().BaseType != typeof(Statement) ||
					stmt.GetType() == typeof(DeclarationStmt) ||
					stmt.GetType() == typeof(ReturnStmt) ||
					stmt.GetType() == typeof(ContinueStmt) ||
					stmt.GetType() == typeof(BreakStmt))
					Write!("", true);

				Visit(stmt);

				if (stmt.GetType().BaseType != typeof(Statement) ||
					stmt.GetType() == typeof(DeclarationStmt) ||
					stmt.GetType() == typeof(ReturnStmt) ||
					stmt.GetType() == typeof(ContinueStmt) ||
					stmt.GetType() == typeof(BreakStmt))
				{
					BreakLine!();
				}
			}
		}

		WriteLine!("}", true);
		return .Continue;
	}

	public override VisitResult Visit(DeferStmt deferStmt)
	{
		Write!("defer", true);
		if (deferStmt.Bind == .Mixin) Write!(":mixin");
		if (deferStmt.Bind == .RootScope) Write!("::");
		BreakLine!();
		Visit(deferStmt.Body);
		return .Continue;
	}

	public override VisitResult Visit(DeclarationStmt declStmt)
	{
		Write!(declStmt.Declaration.Specification.ToString(.. scope .()));
		Write!(" ");

		for (var decl in declStmt.Declaration.Variables)
		{
			Write!(decl.Name);

			if (decl.Initializer != null)
			{
				Write!(" = ");
				Visit(decl.Initializer);
			}

			if (@decl.Index != declStmt.Declaration.Variables.Count - 1)
				Write!(", ");
		}

		Write!(";");
		
		return .Continue;
	}
	
	public override VisitResult Visit(UsingStmt usingStmt)
	{
		Write!("using (", true);
		if (usingStmt.Decl != null)
			Visit(usingStmt.Decl);
		else
			Visit(usingStmt.Expr);
		Write!(")");
		BreakLine!();

		outer: {
			if (usingStmt.Body.GetType() != typeof(CompoundStmt) &&
				usingStmt.Body.GetType() != typeof(UsingStmt))
			{
				scope:outer TemporaryChange<int>(ref mIdentation, mIdentation + 1);
			}
			
			Visit(usingStmt.Body);
		}
		
		return .Continue;
	}
	
	public override VisitResult Visit(IfStmt ifStmt)
	{
		Write!("if (", true);
		Visit(ifStmt.Condition);
		Write!(")");
		BreakLine!();

		outer: {
			if (ifStmt.ThenStatement.GetType() != typeof(CompoundStmt) &&
				ifStmt.ThenStatement.GetType() != typeof(IfStmt) &&
				ifStmt.ThenStatement.GetType() != typeof(AttributedStmt))
				scope:outer TemporaryChange<int>(ref mIdentation, mIdentation + 1);
			
			Visit(ifStmt.ThenStatement);
		}

		if (ifStmt.ElseStatement != null)
		{
			WriteLine!("else", true);

			outer: {
				if (ifStmt.ElseStatement.GetType() != typeof(CompoundStmt) &&
					ifStmt.ElseStatement.GetType() != typeof(IfStmt) &&
					ifStmt.ElseStatement.GetType() != typeof(AttributedStmt))
				{
					scope:outer TemporaryChange<int>(ref mIdentation, mIdentation + 1);
				}
				
				Visit(ifStmt.ElseStatement);
			}
		}

		return .Continue;
	}

	public override VisitResult Visit(ForStmt forStmt)
	{
		Write!("for (", true);
		if (forStmt.Initializers != null)
		{
			for (let expr in forStmt.Initializers)
			{
				Visit(expr);
				if (@expr.Index != forStmt.Initializers.Count - 1)
					Write!(", ");
			}
			Write!("; ");
		}
		else if (forStmt.Declaration != null)
		{
			Visit(forStmt.Declaration);
			Write!(" ");
		}

		Visit(forStmt.Condition);
		Write!("; ");
		for (let expr in forStmt.Incrementors)
		{
			Visit(expr);
			if (@expr.Index != forStmt.Incrementors.Count - 1)
				Write!(", ");
		}
		Write!(")");
		BreakLine!();

		outer: {
			if (forStmt.Body.GetType() != typeof(CompoundStmt))
				scope:outer TemporaryChange<int>(ref mIdentation, mIdentation + 1);
			
			Visit(forStmt.Body);
		}

		return .Continue;
	}

	public override VisitResult Visit(ForeachStmt foreachStmt)
	{
		Write!("for (", true);
		Visit(foreachStmt.TargetType);
		Write!(" ");
		Write!(foreachStmt.TargetName);
		Write!(" in ");
		Visit(foreachStmt.SourceExpr);
		Write!(")");
		BreakLine!();

		outer: {
			if (foreachStmt.Body.GetType() != typeof(CompoundStmt))
				scope:outer TemporaryChange<int>(ref mIdentation, mIdentation + 1);
			
			Visit(foreachStmt.Body);
		}

		return .Continue;
	}

	public override VisitResult Visit(WhileStmt whileStmt)
	{
		Write!("while (", true);
		Visit(whileStmt.Condition);
		Write!(")");
		BreakLine!();

		outer: {
			if (whileStmt.Body.GetType() != typeof(CompoundStmt))
				scope:outer TemporaryChange<int>(ref mIdentation, mIdentation + 1);
			
			Visit(whileStmt.Body);
		}

		return .Continue;
	}

	public override VisitResult Visit(RepeatStmt repeatStmt)
	{
		Write!("repeat", true);
		BreakLine!();

		outer: {
			if (repeatStmt.Body.GetType() != typeof(CompoundStmt))
				scope:outer TemporaryChange<int>(ref mIdentation, mIdentation + 1);
			
			Visit(repeatStmt.Body);
		}

		BreakLine!();
		Write!("while (", true);
		Visit(repeatStmt.Condition);
		Write!(");");

		return .Continue;
	}

	public override VisitResult Visit(DoStmt doStmt)
	{
		WriteLine!("do", true);
		Visit(doStmt.Body);
		return .Continue;
	}

	public override VisitResult Visit(SwitchStmt switchStmt)
	{
		Write!("switch (", true);
		Visit(switchStmt.Expr);
		Write!(")");
		BreakLine!();
		WriteLine!("{", true);

		scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);
		for (let section in switchStmt.Sections)
		{
			Write!("case ", true);
			for (let expr in section.Exprs)
			{
				Visit(expr);
				if (@expr.Index < section.Exprs.Count - 1)
					Write!(", ");
			}
			if (section.WhenExpr != null)
			{
				Write!(" when ");
				Visit(section.WhenExpr);
			}
			WriteLine!(":");

			if (!section.Body.IsEmpty)
			{
				scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);
				for (let stmt in section.Body)
					Visit(stmt);
			}
		}

		if (switchStmt.DefaultSection != null)
		{
			WriteLine!("default:", true);
			if (!switchStmt.DefaultSection.Body.IsEmpty)
			{
				scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);
				for (let stmt in switchStmt.DefaultSection.Body)
					Visit(stmt);
			}
		}

		WriteLine!("}", true);
		return .Continue;
	}

	public override VisitResult Visit(LabeledStmt labeledStmt)
	{
		Write!(labeledStmt.Label, true);
		WriteLine!(":");
		Visit(labeledStmt.Statement);
		return .Continue;
	}

	public override VisitResult Visit(IdentifierExpr identExpr)
	{
		Write!(identExpr.Value);
		return .Continue;
	}

	public override VisitResult Visit(BinaryOpExpr binOpExpr)
	{
		Write!("(");
		Visit(binOpExpr.Left);
		Write!(" ");
		switch (binOpExpr.Operation)
		{
		case .Plus:
			Write!("+");
		case .Minus:
			Write!("-");
		case .Mul:
			Write!("*");
		case .Div:
			Write!("/");
		case .Module:
			Write!("%");
		default:
			Runtime.FatalError("Unknown Token Type");
		}
		Write!(" ");
		Visit(binOpExpr.Right);
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(BitwiseOpExpr bitOpExpr)
	{
		Write!("(");
		Visit(bitOpExpr.Left);
		Write!(" ");
		switch (bitOpExpr.Operation)
		{
		case .LShift:
			Write!("<<");
		case .RArrow: // FIXME
			Write!(">>");
		case .BitwiseOr:
			Write!("|");
		case .BitwiseAnd:
			Write!("&");
		case .BitwiseXor:
			Write!("^");
		default:
			Runtime.FatalError("Unknown Token Type");
		}
		Write!(" ");
		Visit(bitOpExpr.Right);
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(LogicalOpExpr logicalOpExpr)
	{
		Write!("(");
		Visit(logicalOpExpr.Left);
		Write!(" ");
		switch (logicalOpExpr.Operation)
		{
		case .And:
			Write!("&&");
		case .Or:
			Write!("||");
		default:
			Runtime.FatalError("Unknown Token Type");
		}
		Write!(" ");
		Visit(logicalOpExpr.Right);
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(UnaryOpExpr unaryOpExpr)
	{
		switch (unaryOpExpr.Operation)
		{
		case .Plus:
			Write!("+");
		case .Minus:
			Write!("-");
		case .Not:
			Write!("!");
		case .Tilde:
			Write!("~");
		case .Increment:
			Write!("++");
		case .Decrement:
			Write!("--");
		default:
			Runtime.FatalError("Unknown Token Type");
		}
		Write!("(");
		Visit(unaryOpExpr.Right);
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(PostfixOpExpr postfixOpExpr)
	{
		Visit(postfixOpExpr.Left);
		switch (postfixOpExpr.Operation)
		{
		case .Increment:
			Write!("++");
		case .Decrement:
			Write!("--");
		default:
			Runtime.FatalError("Unknown Token Type");
		}
		return .Continue;
	}

	public override VisitResult Visit(ComparisonOpExpr compOpExpr)
	{
		Visit(compOpExpr.Left);
		Write!(" ");
		switch (compOpExpr.Type)
		{
		case .NotEqual:
			Write!("!=");
		case .Equal:
			Write!("==");
		case .StrictEqual:
			Write!("===");
		case .Greater:
			Write!(">");
		case .GreaterEqual:
			Write!(">=");
		case .Lesser:
			Write!("<");
		case .LesserEqual:
			Write!("<=");
		case .Spaceship:
			Write!("<=>");
		case .Is:
			Write!("is");
		case .As:
			Write!("as");
		case .Case:
			Write!("case");
		default:
			Runtime.NotImplemented();
		}
		Write!(" ");
		Visit(compOpExpr.Right);
		return .Continue;
	}

	public override VisitResult Visit(MemberExpr memberExpr)
	{
		if (memberExpr.Left != null)
		{
			Visit(memberExpr.Left);
			if (memberExpr.IsNullable)
				Write!("?");
		}
		Write!(".");
		Visit(memberExpr.Right);
		return .Continue;
	}

	public override VisitResult Visit(CascadeMemberExpr cascadeExpr)
	{
		Visit(cascadeExpr.Left);
		Write!("..");
		Visit(cascadeExpr.Right);
		return .Continue;
	}

	public override VisitResult Visit(AliasedNamespaceMemberExpr aliasedExpr)
	{
		Visit(aliasedExpr.Alias);
		Write!("::");
		Visit(aliasedExpr.Right);
		return .Continue;
	}

	public override VisitResult Visit(MixinMemberExpr memberExpr)
	{
		Visit(memberExpr.Expr);
		Write!("!");
		return .Continue;
	}

	public override VisitResult Visit(IndexOpExpr indexOpExpr)
	{
		Visit(indexOpExpr.Left);
		Write!("[");

		for (var expr in indexOpExpr.Indexes)
		{
			Visit(expr);
			if (@expr.Index != indexOpExpr.Indexes.Count - 1)
				Write!(", ");
		}

		Write!("]");
		return .Continue;
	}
	
	public override VisitResult Visit(CallOpExpr callOpExpr)
	{
		Visit(callOpExpr.Expr);
		Write!("(");
		
		for (var expr in callOpExpr.Params)
		{
			Visit(expr);
			if (@expr.Index != callOpExpr.Params.Count - 1)
				Write!(", ");
		}

		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(TypeOfOpExpr typeOfOpExpr)
	{
		Write!("typeof(");
		Write!(typeOfOpExpr.TypeSpec.ToString(.. scope .()));
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(SizeOfOpExpr sizeOfOpExpr)
	{
		Write!("sizeof(");
		Write!(sizeOfOpExpr.TypeSpec.ToString(.. scope .()));
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(DefaultOpExpr defaultOpExpr)
	{
		Write!("default");
		if (defaultOpExpr.TypeSpec != null)
		{
			Write!("(");
			Write!(defaultOpExpr.TypeSpec.ToString(.. scope .()));
			Write!(")");
		}
		return .Continue;
	}

	public override VisitResult Visit(NewOpExpr newOpExpr)
	{
		if (newOpExpr.IsScope) Write!("scope ");
		else if (newOpExpr.IsAppend) Write!("append ");
		else if (!newOpExpr.IsInplace) Write!("new ");

		Write!(newOpExpr.TypeSpec.ToString(.. scope .()));
		Write!("(");

		if (newOpExpr.Arguments != null)
		{
			for (var expr in newOpExpr.Arguments)
			{
				Visit(expr);
				if (@expr.Index != newOpExpr.Arguments.Count - 1)
					Write!(", ");
			}
		}

		Write!(")");

		if (newOpExpr.Initializer != null)
			Visit(newOpExpr.Initializer);

		return .Continue;
	}

	public override VisitResult Visit(NewArrayOpExpr newArrayOpExpr)
	{
		if (newArrayOpExpr.IsScope) Write!("scope ");
		else if (newArrayOpExpr.IsAppend) Write!("append ");
		else Write!("new ");
		Visit(newArrayOpExpr.TypeSpec);

		if (newArrayOpExpr.Initializer != null)
		{
			Visit(newArrayOpExpr.Initializer);
			Write!(" ");
		}

		return .Continue;
	}

	public override VisitResult Visit(NewArrayImplicitOpExpr newArrayImplicitOpExpr)
	{
		if (newArrayImplicitOpExpr.IsScope) Write!("scope");
		else if (newArrayImplicitOpExpr.IsAppend) Write!("append");
		else Write!("new");

		Write!("[");
		for (int i < newArrayImplicitOpExpr.CommaCount)
			Write!(",");
		Write!("]");

		if (newArrayImplicitOpExpr.Initializer != null)
		{
			Write!(" ");
			Visit(newArrayImplicitOpExpr.Initializer);
		}

		return .Continue;
	}

	public override VisitResult Visit(AssignExpr assignOpExpr)
	{
		Visit(assignOpExpr.Left);
		Write!(" = ");
		Visit(assignOpExpr.Right);
		return .Continue;
	}

	public override VisitResult Visit(CompoundAssignOpExpr cpdAssignOpExpr)
	{
		Visit(cpdAssignOpExpr.Left);
		Write!(" ");
		switch (cpdAssignOpExpr.Operation)
		{
		case .AddAssign:
			Write!("+=");
		case .SubAssign:
			Write!("-=");
		case .MulAssign:
			Write!("*=");
		case .DivAssign:
			Write!("/=");
		case .ModAssign:
			Write!("%=");
		case .LShiftAssign:
			Write!("<<=");
		case .RShiftAssign:
			Write!(">>=");
		case .BitOrAssign:
			Write!("|=");
		case .BitAndAssign:
			Write!("&=");
		case .BitXorAssign:
			Write!("^=");
		default:
			Runtime.FatalError("Unknown Token Type");
		}
		Write!(" ");
		Visit(cpdAssignOpExpr.Right);
		return .Continue;
	}

	public override VisitResult Visit(ReturnStmt retStmt)
	{
		Write!("return");
		if (retStmt.Expr != null)
		{
			Write!(" ");
			Visit(retStmt.Expr);
		}
		Write!(";");
		return .Continue;
	}

	public override VisitResult Visit(BreakStmt brkStmt)
	{
		Write!("break;");
		return .Continue;
	}

	public override VisitResult Visit(ContinueStmt cntStmt)
	{
		Write!("continue;");
		return .Continue;
	}

	public override VisitResult Visit(CastExpr castExpr)
	{
		Write!("("); // TODO: Check if parenteses is necessary
		Write!("(");
		Write!(castExpr.TypeSpec.ToString(.. scope .()));
		Write!(")");
		Visit(castExpr.Expr);
		Write!(")");
		return .Continue;
	}
	
	public override VisitResult Visit(RefExpr refExpr)
	{
		Write!("ref ");
		Visit(refExpr.Expr);
		return .Continue;
	}
	
	public override VisitResult Visit(OutExpr outExpr)
	{
		Write!("out ");
		Visit(outExpr.Expr);
		return .Continue;
	}

	public override VisitResult Visit(VarExpr varExpr)
	{
		Write!("var ");
		Visit(varExpr.Expr);
		return .Continue;
	}

	public override VisitResult Visit(LetExpr letExpr)
	{
		Write!("let ");
		Visit(letExpr.Expr);
		return .Continue;
	}

	public override VisitResult Visit(PointerIndirectionExpr ptrExpr)
	{
		Write!("*");
		Visit(ptrExpr.Expr);
		return .Continue;
	}

	public override VisitResult Visit(AddressOfExpr addrExpr)
	{
		Write!("&");
		Visit(addrExpr.Expr);
		return .Continue;
	}

	public override VisitResult Visit(GenericMemberExpr genMemberExpr)
	{
		Visit(genMemberExpr.Left);
		if (genMemberExpr.IsNullable)
			Write!("?");

		Write!("<");
		for (var param in genMemberExpr.GenericParameters)
		{
			Write!(param.ToString(.. scope .()));
			if (@param.Index != genMemberExpr.GenericParameters.Count - 1)
				Write!(", ");
		}
		Write!(">");
		return .Continue;
	}

	public override VisitResult Visit(ExpressionStmt exprStmt)
	{
		Write!("", true);
		Visit(exprStmt.Expr);
		WriteLine!(";");
		return .Continue;
	}

	public override VisitResult Visit(ArrayInitExpr arrayInitExpr)
	{
		Write!("{ ");

		for (var expr in arrayInitExpr.Values)
		{
			Visit(expr);
			if (@expr.Index != arrayInitExpr.Values.Count - 1)
				Write!(", ");
		}

		Write!(" }");
		return .Continue;
	}

	public override VisitResult Visit(ObjectInitExpr objectInitExpr)
	{
		BreakLine!();

		Write!("{\n", true);
		{
			scope TemporaryChange<int>(ref mIdentation, mIdentation + 1);

			for (let init in objectInitExpr.Initializers)
			{
				Write!("", true);
				Visit(init);

				if (@init.Index != objectInitExpr.Initializers.Count - 1)
					Write!(",\n");
			}
		}
		BreakLine!();
		Write!("}", true);
		return .Continue;
	}

	public override VisitResult Visit(LambdaOpExpr node)
	{
		Write!("(");
		for (var parameter in node.FormalParameters)
		{
			Write!(parameter);
			if (@parameter.Index != node.FormalParameters.Count - 1)
				Write!(", ");
		}
		Write!(") => ");

		if (node.Expr != null)
		{
			Visit(node.Expr);
		}
		else
		{
			Visit(node.Statement);

		}
		return .Continue;
	}

	public override VisitResult Visit(VoidTypeSpec node)
	{
		Write!("void");
		return .Continue;
	}

	public override VisitResult Visit(DotTypeSpec node)
	{
		Write!(".");
		return .Continue;
	}

	public override VisitResult Visit(VarTypeSpec node)
	{
		Write!("var");
		return .Continue;
	}

	public override VisitResult Visit(LetTypeSpec node)
	{
		Write!("let");
		return .Continue;
	}

	public override VisitResult Visit(ArrayTypeSpec node)
	{
		Debug.Assert(node.Sizes.IsEmpty || node.Sizes.All((s) => s == null));

		Visit(node.Element);

		Write!("[");
		for (var expr in node.Sizes)
		{
			if (expr != null)
			{
				Visit(expr);
				
				if (@expr.Index != node.Sizes.Count - 1)
					Write!(", ");
			}
			else
				Write!(", ");
		}
		Write!("]");
		
		return .Continue;
	}

	public override VisitResult Visit(NullableTypeSpec node)
	{
		Visit(node.Element);
		Write!("?");
		return .Continue;
	}

	public override VisitResult Visit(PointerTypeSpec node)
	{
		Visit(node.Element);
		Write!("*");
		return .Continue;
	}

	public override VisitResult Visit(RefTypeSpec node)
	{
		Write!("ref ");
		Visit(node.Element);
		return .Continue;
	}

	public override VisitResult Visit(DelegateTypeSpec node)
	{
		Write!(node.Type == .Delegate ? "delegate " : "function ");
		Write!(node.ReturnType);
		Write!("(");

		for (var param in node.Params)
		{
			WriteParamDecl(param);
			if (@param.Index != node.Params.Count - 1)
				Write!(", ");
		}

		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(ExprModTypeSpec node)
	{
		Write!(node.Type == .DeclType ? "decltype(" : "comptype(");
		Visit(node.Expr);
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(SimpleName node)
	{
		Write!(node.Identifier);
		return .Continue;
	}

	public override VisitResult Visit(IdentifierName node)
	{
		Write!(node.Identifier);
		return .Continue;
	}

	public override VisitResult Visit(GenericName node)
	{
		Write!(node.Identifier);

		if (!node.TypeArguments.IsEmpty)
		{
			Write!("<");
			int i = 0; // TODO: Do the separation in a better way
			for (var param in node.TypeArguments)
			{
				Visit(param);
				if (++i != node.TypeArguments.Count)
					Write!(", ");
			}
			Write!(">");
		}

		return .Continue;
	}

	public override VisitResult Visit(QualifiedName node)
	{
		Visit(node.Left);
		Write!('.');
		Visit(node.Right);
		return .Continue;
	}

	public override VisitResult Visit(AttributedExpr node)
	{
		if (!node.Attributes.IsEmpty)
			WriteAttributes(node.Attributes);
		Visit(node.Expr);
		return .Continue;
	}

	public override VisitResult Visit(NewInterpolatedStringOpExpr node)
	{
		if (node.IsScope) Write!("scope ");
		else if (node.IsAppend) Write!("append ");
		else Write!("new ");
		Visit(node.Expr);
		return .Continue;
	}

	public override VisitResult Visit(NewLambdaOpExpr node)
	{
		if (node.IsScope) Write!("scope ");
		else if (node.IsAppend) Write!("append ");
		else Write!("new ");
		Visit(node.Expr);
		return .Continue;
	}

	public override VisitResult Visit(InterpolatedStringExpr node)
	{
		for (int i = 0; i < node.BraceCount; i++)
		    Write!('$');

		Write!("\"");
		for (var expr in node.Exprs)
		{
			if (var strLiteral = expr as StrLiteral)
			{
				String escapedText = scope .();
				String.Escape(strLiteral.Value.Ptr, strLiteral.Value.Length, escapedText);
				Write!(escapedText);
			}
			else
			{
				for (int i = 0; i < node.BraceCount; i++)
				    Write!('{');
				Visit(expr);
				for (int i = 0; i < node.BraceCount; i++)
				    Write!('}');
			}
		}
		Write!("\"");

		return .Continue;
	}

	public override VisitResult Visit(RangeExpr node)
	{
		Visit(node.Left);
		switch (node.Type)
		{
		case .DotDotDot:
			Write!("...");
		case .UpToRange:
			Write!("..<");
		default:
			Runtime.FatalError("Unknown Token Type");
		}
		Visit(node.Right);
		return .Continue;
	}

	public override VisitResult Visit(DeleteOpExpr node)
	{
		Write!("delete ");
		Visit(node.Expr);
		return .Continue;
	}

	public override VisitResult Visit(CondOpExpr node)
	{
		Write!("(");
		Visit(node.Expr);
		Write!(" ? ");
		Visit(node.TrueExpr);
		Write!(" : ");
		Visit(node.FalseExpr);
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(NullCondOpExpr node)
	{
		Write!("(");
		Visit(node.Expr);
		Write!(" ?? ");
		Visit(node.NullExpr);
		Write!(")");
		return .Continue;
	}

	public override VisitResult Visit(UninitializedExpr node)
	{
		Write!("?");
		return .Continue;
	}
}
