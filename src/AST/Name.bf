using System;
using System.Collections;

namespace BeefParser.AST
{
	abstract class Name : TypeSpec
	{
		public abstract StringView Value { get; }
	}
	
	abstract class SimpleName : Name
	{
		private String mIdentifier ~ delete _;

		public StringView Identifier
		{
			get => mIdentifier;
			set => String.NewOrSet!(mIdentifier, value);
		}

		public override StringView Value => Identifier;
	}
	
	[ImplementAccept, ImplementToString]
	class IdentifierName : SimpleName
	{
	}
	
	[ImplementAccept, ImplementToString]
	class GenericName : SimpleName
	{
		public List<TypeSpec> TypeArguments = new .() ~ Release!(_);
	}
	
	[ImplementAccept, ImplementToString]
	class QualifiedName : Name
	{
		public Name Left ~ delete _;
		public SimpleName Right ~ delete _;

		public override StringView Value => Right.Identifier;
	}
}
