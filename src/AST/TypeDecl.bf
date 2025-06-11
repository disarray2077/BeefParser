using System;
using System.Collections;

namespace BeefParser.AST
{
	abstract class BaseTypeDecl : MemberDecl
	{
		public String mName ~ delete _;

		public StringView Name
		{
			get => mName;
			set => String.NewOrSet!(mName, value);
		}
	}

	abstract class TypeDecl : BaseTypeDecl
	{
		public List<String> GenericParametersNames = new .() ~ Release!(_);
		public List<TypeSpec> Inheritance = new .() ~ Release!(_);
		public List<GenericConstraintDecl> GenericConstraints = new .() ~ Release!(_);
		public List<Declaration> Declarations = new .() ~ Release!(_);
	}
}
