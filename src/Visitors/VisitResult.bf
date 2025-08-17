namespace BeefParser.AST;

enum VisitResult
{
	/// Continue visiting the remaining siblings of this node.
	Continue,
	/// Skip the remaining siblings of this node and continue from the parent's next sibling.
	SkipAndContinue,
	/// Abort the entire traversal immediately.
	Stop
}