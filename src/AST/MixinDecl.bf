using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class MixinDecl : MemberDecl
	{
		private String mName ~ delete _;
		public List<String> GenericParametersNames = new .() ~ Release!(_);
		public List<GenericConstraintDecl> GenericConstraints = new .() ~ Release!(_);
		public List<ParamDecl> FormalParameters = new .() ~ Release!(_);
		public List<Statement> Statements = new .() ~ Release!(_);
		public Expression ReturnExpr ~ delete _;

		public StringView Name
		{
			get => mName;
			set => String.NewOrSet!(mName, value);
		}
	}
}
