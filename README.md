# BeefParser

BeefParser provides a parser for the Beef programming language, implemented entirely in Beef. It's designed to take Beef source code as input and produce a structured Abstract Syntax Tree (AST) that represents the code's syntax and semantics. This AST can then be used for various purposes like static analysis, code generation or code transformation.

## ⚠️ Disclaimer & Current Status ⚠️

BeefParser is currently **not under active development** and should be considered **experimental**.

*   **Incomplete Feature Coverage:** It does not support all features and edge cases of the Beef programming language.
*   **Limited Testing:** While unit tests exist (see `BeefParser.Tests`), the parser has **not been thoroughly tested** against a wide range of complex Beef projects.
*   **Known and Unknown Bugs:** You may run into parsing issues, incorrect ASTs, or other bugs.

You're welcome to try it out, just keep its current limitations in mind.

## Usage

### Parsing Beef Source and Inspecting the AST

Here's a basic example of how to parse existing Beef code and then inspect the generated Abstract Syntax Tree:

```bf
using System;
using BeefParser;
using BeefParser.AST;

namespace MyProject
{
    class Program
    {
        public static void Main()
        {
            String beefCode =
                """
                namespace TestApp
                {
                    public class MyClass
                    {
                        public static void DoSomething(String message)
                        {
                            Console.WriteLine(message);
                        }
                    }
                }
                """;

            // 1. Create a parser instance
            let parser = scope BeefParser(beefCode);

            // 2. Parse the code
            Runtime.Assert(parser.Parse(let root) case .Ok, "Parsing failed!");
            defer delete root; // Important: manage memory for the AST root

            // 3. Inspect the AST
            if (root.Declarations.Count > 0)
            {
                if (let namespaceDecl = root.Declarations[0] as NamespaceDecl)
                {
                    Console.WriteLine($"Parsed namespace: {namespaceDecl.Name.Value}");

                    if (namespaceDecl.Declarations.Count > 0 &&
                        (let classDecl = namespaceDecl.Declarations[0] as ClassDecl))
                    {
                        Console.WriteLine($" - Found class: {classDecl.Name}");
                        for (var member in classDecl.Declarations)
                        {
                            if (let methodDecl = member as MethodDecl)
                            {
                                Console.WriteLine($"   - Method: {methodDecl.Name}");
                            }
                        }
                    }
                }
            }
        }
    }
}
```

### Creating AST statements with String Interpolation

This library allows you to create AST statements using Beef’s string interpolation. This is particularly useful for code generation or dynamic AST construction.

In the example below, the `$"""..."""` string is treated as a snippet of source code. When passed to collections like `myStatements`, which expect `Statement` nodes, the `Add` method parses the string into its corresponding AST representation and appends it to the list.

```bf
using System;
using BeefParser;
using BeefParser.AST;

namespace MyProject
{
    class Program
    {
        public static void Main()
        {
            let featureId = 5;
            let trueMessage = "Feature is active!";
            let myStatements = scope List<Statement>();
            defer { ClearAndDeleteItems!(myStatements); }

            myStatements.Add($$"""
                if (CheckFeature({{featureId}}))
                {
                    Log("{{trueMessage}}");
                    UpdateState({{featureId}});
                }
                else
                {
                    Log("Feature is disabled.");
                    UpdateState(0);
                }
            """);

            Runtime.Assert(myStatements.Count == 1 && myStatements[0] is IfStmt);
        }
    }
}
```