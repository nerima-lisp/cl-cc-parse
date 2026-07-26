;;;; cl-cc-parse.asd — True-encapsulation ASDF system for the parse subsystem
;;;;
;;;; Phase 3 of the package-by-feature monorepo migration.
;;;; All parse source files are now (in-package :cl-cc/parse).
;;;; The umbrella :cl-cc uses :cl-cc/parse and re-exports via do-external-symbols.

(asdf:defsystem :cl-cc-parse
  :description "CL-CC Parse subsystem: CST, lexer, parser, and lowering"
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :homepage "https://github.com/nerima-lisp/cl-cc-parse"
  :bug-tracker "https://github.com/nerima-lisp/cl-cc-parse/issues"
  :source-control (:git "https://github.com/nerima-lisp/cl-cc-parse.git")
  :version "0.1.0"
  :depends-on (:cl-cc-ast :cl-cc-bootstrap)
  :pathname "src"
  :serial t
  :components
  ((:file "package")
   (:file "cst")
   (:file "diagnostics")
   (:file "lexer")
   (:file "lexer-number")
   (:file "lexer-readers")
   (:file "lexer-skip")
   (:file "lexer-dispatch")
   (:file "incremental")
   (:file "pratt")
   (:file "combinators")
   (:module "cl"
    :serial t
    :components
    ((:file "parser")
     (:file "parser-sexp-lowering")
     (:file "lower")
     (:file "lower-setf")
     (:file "lower-definitions")
     (:file "lower-clos")
     (:file "parser-roundtrip")
      (:file "grammar-token-stream")
      (:file "grammar")
      (:file "grammar-entrypoints")))
   (:file "cst-to-ast")))

(asdf:defsystem "cl-cc-parse/test"
  :description "Module boundary tests for cl-cc-parse"
  :author "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :depends-on ("cl-cc-parse" "cl-weave")
  :pathname "t"
  :serial t
  :components ((:file "package")
               (:file "parse-boundary-test"))
  :perform (asdf:test-op (op system)
             (declare (ignore op system))
             (uiop:symbol-call :cl-weave :run-all-tests :pass-with-no-tests nil)))
