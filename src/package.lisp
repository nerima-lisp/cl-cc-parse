;;;; Package declarations for the parse feature modules and compatibility facade.
;;;; Feature packages own implementation symbols; the facade preserves the W0 API.

(defpackage :cl-cc/parse
  (:use :cl)
  (:import-from :cl-cc/parse/cst
   #:cst-error #:cst-error-message #:cst-error-p #:cst-child #:cst-children #:cst-collect-errors #:cst-equal-p #:cst-interior #:cst-interior-children #:cst-interior-p #:cst-location-string #:cst-node #:cst-node-end-byte #:cst-node-kind #:cst-node-p #:cst-node-source-file #:cst-node-start-byte #:cst-to-sexp #:cst-token #:cst-token-p #:cst-token-value #:cst-trivia #:cst-walk #:make-cst-error #:make-cst-interior #:make-cst-trivia #:sexp-head-to-kind #:sexp-to-cst)
  (:import-from :cl-cc/parse/diagnostics
   #:byte-offset-to-line-col #:diagnostic #:diagnostic-error-code #:diagnostic-fix-it #:diagnostic-message #:diagnostic-severity #:diagnostic-span #:did-you-mean #:fix-it #:fix-it-span #:fix-it-text #:format-diagnostic #:format-diagnostic-list #:make-diagnostic #:make-fix-it #:make-parse-error #:make-parse-warning #:parse-failure #:source-line-at #:undefined-symbol-diagnostic #:warning-as-error-p #:*werror-categories* #:*werror-p*)
  (:import-from :cl-cc/parse/reader
   #:lex-all #:lexer-read-token #:lexer-token #:lexer-token-column #:lexer-token-end-byte #:lexer-token-line #:lexer-token-start-byte #:lexer-token-trivia #:make-lexer)
  (:import-from :cl-cc/parse/incremental
   #:cache-lookup #:cache-store #:edit-operation #:invalidate-parse-cache #:make-edit-operation #:parse-incremental)
  (:import-from :cl-cc/parse/grammar
   #:*grammar-rules* #:clear-grammar-rules #:def-grammar-rule #:parse-all-forms #:parse-cl-source #:parse-cl-source-single #:parse-combinator #:parse-ok-p #:parse-source #:parse-source-for-language #:parse-with-grammar #:query-grammar)
  (:import-from :cl-cc/parse/lowering
   #:lambda-list-has-extended-p #:lower-cst-list-to-ast #:lower-cst-to-ast #:lower-sexp-to-ast #:parse-and-lower #:parse-and-lower-one #:parse-compiler-lambda-list #:parse-slot-spec)
  (:export
   #:cst-error
   #:cst-error-message
   #:cst-error-p
   #:cst-child
   #:cst-children
   #:cst-collect-errors
   #:cst-equal-p
   #:cst-interior
   #:cst-interior-children
   #:cst-interior-p
   #:cst-location-string
   #:cst-node
   #:cst-node-end-byte
   #:cst-node-kind
   #:cst-node-p
   #:cst-node-source-file
   #:cst-node-start-byte
   #:cst-to-sexp
   #:cst-token
   #:cst-token-p
   #:cst-token-value
   #:cst-trivia
   #:cst-walk
   #:make-cst-error
   #:make-cst-interior
   #:make-cst-trivia
   #:sexp-head-to-kind
   #:sexp-to-cst
   #:byte-offset-to-line-col
   #:diagnostic
   #:diagnostic-error-code
   #:diagnostic-fix-it
   #:diagnostic-message
   #:diagnostic-severity
   #:diagnostic-span
   #:did-you-mean
   #:fix-it
   #:fix-it-span
   #:fix-it-text
   #:format-diagnostic
   #:format-diagnostic-list
   #:make-diagnostic
   #:make-fix-it
   #:make-parse-error
   #:make-parse-warning
   #:parse-failure
   #:source-line-at
   #:undefined-symbol-diagnostic
   #:warning-as-error-p
   #:*werror-categories*
   #:*werror-p*
   #:lex-all
   #:lexer-read-token
   #:lexer-token
   #:lexer-token-column
   #:lexer-token-end-byte
   #:lexer-token-line
   #:lexer-token-start-byte
   #:lexer-token-trivia
   #:make-lexer
   #:cache-lookup
   #:cache-store
   #:edit-operation
   #:invalidate-parse-cache
   #:make-edit-operation
   #:parse-incremental
   #:*grammar-rules*
   #:clear-grammar-rules
   #:def-grammar-rule
   #:parse-all-forms
   #:parse-cl-source
   #:parse-cl-source-single
   #:parse-combinator
   #:parse-ok-p
   #:parse-source
   #:parse-source-for-language
   #:parse-with-grammar
   #:query-grammar
   #:lambda-list-has-extended-p
   #:lower-cst-list-to-ast
   #:lower-cst-to-ast
   #:lower-sexp-to-ast
   #:parse-and-lower
   #:parse-and-lower-one
   #:parse-compiler-lambda-list
   #:parse-slot-spec))
