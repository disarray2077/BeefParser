using System;
using System.Collections;

namespace BeefParser.AST
{
	abstract class MemberDecl : Declaration
	{
		public List<AttributeSpec> Attributes ~ Release!(_);
		public AccessLevel AccessLevel;
		public Modifier Modifiers;
	}
}
