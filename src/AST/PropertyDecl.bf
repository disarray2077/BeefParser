using System;
using System.Collections;

namespace BeefParser.AST
{
	abstract class BasePropertyDecl : MemberDecl
	{
		public TypeSpec Specification ~ delete _;
		public Name ExplicitInterfaceName ~ delete _; // for explicit interface implementations
		public String mName ~ delete _;
		public List<PropertyAccessor> Accessors = new .() ~ Release!(_);

		public StringView Name
		{
			get => mName;
			set => String.NewOrSet!(mName, value);
		}
	}

	[ImplementAccept, ImplementToString]
	class PropertyDecl : BasePropertyDecl
	{
	}
}
