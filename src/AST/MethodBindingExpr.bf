namespace BeefParser.AST;

[ImplementAccept, ImplementToString]
class MethodBindingExpr : Expression
{
	public Expression Target ~ delete _;
}
