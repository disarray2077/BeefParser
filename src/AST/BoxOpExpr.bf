namespace BeefParser.AST;

[ImplementAccept, ImplementToString]
class BoxOpExpr : Expression
{
	public bool IsAppend;
	public bool IsScope;
	public BindingSpec Bind ~ delete _;
	public Expression Expr ~ delete _;
}
