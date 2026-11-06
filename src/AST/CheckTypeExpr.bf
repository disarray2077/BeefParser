namespace BeefParser.AST;

[ImplementAccept, ImplementToString]
class CheckTypeExpr : Expression
{
	public Expression Target ~ delete _;
	public TypeSpec TypeSpec ~ delete _;
}
