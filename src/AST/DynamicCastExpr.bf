namespace BeefParser.AST;

[ImplementAccept, ImplementToString]
class DynamicCastExpr : Expression
{
	public Expression Target ~ delete _;
	public TypeSpec TypeSpec ~ delete _;
}
