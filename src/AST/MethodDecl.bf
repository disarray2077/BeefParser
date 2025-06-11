using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class MethodDecl : MemberDecl
	{
		public TypeSpec Specification ~ delete _;
		private String mInterfaceName ~ delete _;
		private String mName ~ delete _;
		public CallOpExpr InhenritanceCall ~ delete _;
		public List<String> GenericParametersNames = new .() ~ Release!(_);
		public List<GenericConstraintDecl> GenericConstraints = new .() ~ Release!(_);
		public List<ParamDecl> FormalParameters = new .() ~ Release!(_);
		public Statement CompoundStmt ~ delete _;
		public bool IsConstructor;
		public bool IsDestructor;
		public bool IsOperator;
		public bool IsMixin;
		public bool IsMutable;
		public OperatorType OperatorType;

		// for explicit interface implementations
		public StringView InterfaceName
		{
			get => mInterfaceName;
			set => String.NewOrSet!(mInterfaceName, value);
		}

		public StringView Name
		{
			get
			{
				if (IsOperator)
					Runtime.FatalError("Tried to get name of operator!!");
				return mName;
			}
			set => String.NewOrSet!(mName, value);
		}
	}
}
