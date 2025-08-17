using System;
using System.Collections;

namespace BeefParser.AST
{
	[ImplementAccept, ImplementToString]
	class EnumCaseDecl : Declaration
	{
    	public List<EnumCaseItem> Items = new .() ~ Release!(_);
	}
	
	[ImplementAccept, ImplementToString]
	public class EnumCaseItem : ASTNode
	{
	    private String mName;
	    public List<ParamDecl> Parameters = new .() ~ Release!(_);

		public StringView Name
		{
			get => mName;
			set => String.NewOrSet!(mName, value);
		}
	}
}
