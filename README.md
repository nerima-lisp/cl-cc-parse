# cl-cc-parse

The reader, lexer and AST lowering for the
[cl-cc](https://github.com/nerima-lisp/cl-cc) Common Lisp compiler — source
text and s-expressions in, `cl-cc-ast` nodes out.

Depends only on [`cl-cc-ast`](https://github.com/nerima-lisp/cl-cc-ast) and
[`cl-cc-bootstrap`](https://github.com/nerima-lisp/cl-cc-bootstrap).

## Why this one mattered

It was the last of four dependencies keeping
[`cl-cc-php`](https://github.com/nerima-lisp/cl-cc-php) and
[`cl-cc-javascript`](https://github.com/nerima-lisp/cl-cc-javascript) tied to
cl-cc as a whole. Both declare
`(cl-cc-ast cl-cc-bootstrap cl-cc-parse cl-cc-vm)`, and every one but this had
already been extracted — so both still took cl-cc as a flake input, and cl-cc
taking them back would have been a cycle.

With this out, neither backend depends on cl-cc, and cl-cc can take both as
inputs while keeping `:language :php` and `:language :javascript` exactly as
they are.

## Usage

```lisp
(asdf:load-system "cl-cc-parse")
```

## Development

```sh
nix develop
nix flake check
```

## License

MIT
