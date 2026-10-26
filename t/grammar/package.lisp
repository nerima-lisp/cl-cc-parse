(defpackage :cl-cc/parse/grammar/test
  (:use :cl)
  (:import-from :cl-weave
                :describe-concurrent :describe-sequential
                :it-sequential :it :expect :signals)
  (:import-from :cl-cc/parse/grammar
                :clear-grammar-rules :def-grammar-rule
                :parse-combinator :parse-ok-p :query-grammar
                :make-pratt-context
                :pratt-context-tokens :pratt-context-nud-table
                :pratt-context-led-table :pratt-parse-expr)
  (:export :make-test-ctx :parse-one-cst :parse-one-sexp))
