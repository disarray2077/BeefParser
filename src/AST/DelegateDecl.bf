using System.Collections;
using System;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class DelegateDecl : BaseTypeDecl
	{
		public bool IsFunction;
		public TypeSpec Specification ~ delete _;
		public List<String> GenericParametersNames = new .() ~ Release!(_);
		public List<GenericConstraintDecl> GenericConstraints = new .() ~ Release!(_);
		public List<ParamDecl> FormalParameters = new .() ~ Release!(_);
	}
}
