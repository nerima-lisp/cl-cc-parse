## cst

- Definition: A concrete syntax tree (CST) preserves source forms, comments and whitespace (trivia), and UTF-8 byte spans.
- Package: `cl-cc/parse/cst`
- Key types: `cst-node`, `cst-token`, `cst-interior`, `cst-error`, `cst-trivia`
- Key functions: `cst-child`, `cst-children`, `cst-walk`, `cst-collect-errors`, `cst-equal-p`, `cst-location-string`, `cst-to-sexp`, `sexp-to-cst`, `sexp-head-to-kind`, `make-cst-error`, `make-cst-interior`, `make-cst-trivia`
- Other contexts: An abstract syntax tree (AST) represents compiler meaning and discards source details that the CST preserves.

## diagnostics

- Definition: Diagnostics describe parse and warning results with source locations and optional fixes.
- Package: `cl-cc/parse/diagnostics`
- Key types: `diagnostic`, `fix-it`, `parse-failure`
- Key functions: `make-diagnostic`, `make-fix-it`, `make-parse-error`, `make-parse-warning`, `format-diagnostic`, `format-diagnostic-list`, `byte-offset-to-line-col`, `source-line-at`, `did-you-mean`, `undefined-symbol-diagnostic`, `warning-as-error-p`
- Other contexts: Parser combinators compose smaller parsers, and their failure status controls backtracking, such as trying another branch. That status is separate from a user-facing diagnostic.

## reader

- Definition: The reader performs lexical analysis: it turns Common Lisp (CL) source into tokens and records trivia (comments and whitespace) with UTF-8 byte positions.
- Package: `cl-cc/parse/reader`
- Key types: `lexer-token`
- Key functions: `make-lexer`, `lex-all`, `lexer-read-token`, `lexer-token-start-byte`, `lexer-token-end-byte`, `lexer-token-line`, `lexer-token-column`, `lexer-token-trivia`
- Other contexts: `lexer-token` is the token type used by the CL parser. The grammar adapter converts these tokens to cl-parser-kit tokens internally and maps parse results back.

## incremental

- Definition: Incremental parsing applies a byte-range edit to an existing CST, reparses the affected region through a callback, and shifts later nodes by the edit's byte-length change.
- Package: `cl-cc/parse/incremental`
- Key types: `edit-operation`
- Key functions: `make-edit-operation`, `parse-incremental`, `cache-lookup`, `cache-store`, `invalidate-parse-cache`
- Other contexts: Incremental parsing accepts a parser callback and leaves grammar rules and parser implementation to its caller.

## grammar

- Definition: Grammar owns named-rule dispatch and Common Lisp (CL) entry points that parse source into CST nodes. Generic combinator and Pratt parsing is delegated through a private adapter to cl-parser-kit.
- Package: `cl-cc/parse/grammar`
- Key types: None.
- Key functions: `def-grammar-rule`, `query-grammar`, `clear-grammar-rules`, `parse-combinator`, `parse-ok-p`, `parse-with-grammar`, `parse-source`, `parse-all-forms`, `parse-cl-source`, `parse-cl-source-single`, `parse-source-for-language`
- Other contexts: Grammar expressions compose parsers for token sequences. `parse-cl-source` returns CST nodes, while `parse-source` returns S-expressions; lowering converts either form into abstract syntax tree (AST) nodes.

## lowering

- Definition: Lowering translates CST nodes or parsed S-expressions into the compiler's abstract syntax tree (AST).
- Package: `cl-cc/parse/lowering`
- Key types: None.
- Key functions: `lower-cst-to-ast`, `lower-cst-list-to-ast`, `parse-and-lower`, `parse-and-lower-one`, `parse-compiler-lambda-list`, `lambda-list-has-extended-p`, `parse-slot-spec`, `lower-sexp-to-ast`
- Other contexts: AST nodes represent compiler semantics; unlike CST nodes, they do not preserve comments, whitespace, or exact source spans.
