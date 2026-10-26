(asdf:defsystem :cl-cc-parse
  :description "CL-CC Parse subsystem: CST, reader, grammar, and lowering"
  :author "takeokunn <bararararatty@gmail.com>"
  :maintainer "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :homepage "https://github.com/nerima-lisp/cl-cc-parse"
  :bug-tracker "https://github.com/nerima-lisp/cl-cc-parse/issues"
  :source-control (:git "https://github.com/nerima-lisp/cl-cc-parse.git")
  :version "0.1.1"
  :depends-on (:cl-cc-ast :cl-cc-bootstrap :cl-parser-kit)
  :in-order-to ((test-op (test-op "cl-cc-parse/test")))
  :pathname "src"
  :serial t
  :components
  ((:file "cst/package")
   (:file "diagnostics/package")
   (:file "reader/package")
   (:file "incremental/package")
   (:file "grammar/package")
   (:file "lowering/package")
   (:file "package")
   (:module "cst"
    :serial t
    :components ((:file "cst")))
   (:module "diagnostics"
    :serial t
    :components ((:file "diagnostics")))
   (:module "reader"
    :serial t
    :components
    ((:file "lexer")
     (:file "lexer-number")
     (:file "lexer-readers")
     (:file "lexer-skip")
     (:file "lexer-dispatch")
     (:module "cl"
      :serial t
      :components ((:file "lexer")))))
   (:module "incremental"
    :serial t
    :components ((:file "incremental")))
   (:module "grammar"
    :serial t
    :components
    ((:file "kit-adapter")
     (:file "pratt")
     (:file "combinators")
     (:module "cl"
      :serial t
      :components
      ((:file "token-stream")
       (:file "grammar")
       (:file "entrypoints")
       (:file "parser-entrypoints")))))
   (:module "lowering"
    :serial t
    :components
    ((:module "cl"
      :serial t
      :components
      ((:file "parser")
       (:file "parser-sexp-lowering")
       (:file "lower")
       (:file "lower-setf")
       (:file "lower-definitions")
       (:file "lower-clos")))
     (:file "cst-to-ast")))))
(asdf:defsystem "cl-cc-parse/test"
  :description "Feature boundary tests for cl-cc-parse"
  :author "takeokunn <bararararatty@gmail.com>"
  :license "MIT"
  :depends-on ("cl-cc-parse" "cl-weave")
  :pathname "t"
  :serial t
  :components
  ((:file "package")
   (:module "cst"
    :serial t
    :components ((:file "package") (:file "suite")))
   (:module "diagnostics"
    :serial t
    :components ((:file "package") (:file "suite")))
   (:module "reader"
    :serial t
    :components
    ((:file "package")
     (:file "suite")
     (:file "parse-boundary-test")))
   (:module "incremental"
    :serial t
    :components ((:file "package") (:file "suite")))
   (:module "grammar"
    :serial t
    :components ((:file "package") (:file "suite") (:file "kit-adapter-tests")))
   (:module "lowering"
    :serial t
    :components ((:file "package") (:file "suite"))))
  :perform (asdf:test-op (operation system)
             (declare (ignore operation system))
             (unless (uiop:symbol-call :cl-weave :run-all
                                       :reporter :spec
                                       :pass-with-no-tests nil)
               (error "cl-cc-parse tests failed"))))
