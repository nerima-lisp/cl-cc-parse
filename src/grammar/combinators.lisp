(in-package :cl-cc/parse/grammar)

(defvar *grammar-rules* (make-hash-table)
  "Grammar rule database mapping keyword names to combinator expressions.")

(defmacro def-grammar-rule (name combinator-expr)
  "Store COMBINATOR-EXPR under keyword NAME."
  `(setf (gethash ,name *grammar-rules*) ',combinator-expr))

(defun query-grammar (name)
  "Return the combinator expression registered for NAME."
  (gethash name *grammar-rules*))

(defun clear-grammar-rules ()
  "Remove every registered grammar rule."
  (clrhash *grammar-rules*))

(defun stream-empty-p (stream)
  (null stream))

(defun stream-peek (stream)
  (car stream))

(defun stream-consume (stream)
  (if stream
      (values (car stream) (cdr stream))
      (values nil nil)))

(defun tok-type (token)
  (getf token :type))

(defun tok-value (token)
  (getf token :value))

(defun %compile-combinator (expr)
  (labels ((compile-child (child)
             (%compile-combinator child))
           (dynamic-rule-parser (name)
             (cl-parser-kit:make-parser
              :name (list :rule name)
              :fn (lambda (input position)
                    (let ((rule-expr (query-grammar name)))
                      (if rule-expr
                          (cl-parser-kit:run-parser
                           (cl-parser-kit:attempt
                            (compile-child rule-expr))
                           input position)
                          (error "No grammar rule defined for: ~S" name)))))))
    (cond
      ((keywordp expr)
       (dynamic-rule-parser expr))
      ((not (consp expr))
       (error "Invalid combinator expression: ~S" expr))
      (t
       (let ((op (and (symbolp (car expr))
                      (intern (symbol-name (car expr)) :keyword))))
         (case op
           (:token
            (%legacy-token-parser (cadr expr) (caddr expr)))
           (:literal
            (%legacy-token-parser :T-IDENT (cadr expr)))
           (:seq
            (cl-parser-kit:attempt
             (apply #'cl-parser-kit:seq
                    (mapcar #'compile-child (cdr expr)))))
           (:alt
            (apply #'cl-parser-kit:alt
                   (mapcar #'compile-child (cdr expr))))
           (:many
            (%legacy-many-parser (compile-child (cadr expr))))
           (:many1
            (%legacy-many1-parser (compile-child (cadr expr))))
           (:opt
            (%legacy-option-parser (compile-child (cadr expr))))
           (:rule
            (dynamic-rule-parser (cadr expr)))
           (t
            (error "Unknown combinator operator: ~S" (car expr)))))))))

(defun parse-combinator (expr stream)
  "Parse STREAM with EXPR through cl-parser-kit."
  (%run-legacy-kit-parser (%compile-combinator expr) stream))

(defun parse-ok-p (value)
  (not (eq value :fail)))

(defun parse-token* (type value stream)
  "Match one token by type and optional value."
  (%run-legacy-kit-parser (%legacy-token-parser type value) stream))

(defun parse-literal* (string stream)
  "Match one identifier token with STRING as its value."
  (parse-token* :T-IDENT string stream))

(defun parse-seq* (exprs stream)
  "Parse EXPRS in order and return their values as a list."
  (%run-legacy-kit-parser
   (cl-parser-kit:attempt
    (apply #'cl-parser-kit:seq (mapcar #'%compile-combinator exprs)))
   stream))

(defun parse-alt* (exprs stream)
  "Return the first successful parse in EXPRS."
  (%run-legacy-kit-parser
   (apply #'cl-parser-kit:alt (mapcar #'%compile-combinator exprs))
   stream))

(defun parse-many* (expr stream)
  "Parse zero or more instances of EXPR."
  (%run-legacy-kit-parser
   (%legacy-many-parser (%compile-combinator expr))
   stream))

(defun parse-many1* (expr stream)
  "Parse one or more instances of EXPR."
  (%run-legacy-kit-parser
   (%legacy-many1-parser (%compile-combinator expr))
   stream))

(defun parse-opt* (expr stream)
  "Parse EXPR or return :OPT-ABSENT without consuming input."
  (%run-legacy-kit-parser
   (%legacy-option-parser (%compile-combinator expr))
   stream))

(defun parse-rule (name stream)
  "Resolve NAME from the mutable grammar registry and parse it."
  (parse-combinator (list :rule name) stream))

(defun parse-with-grammar (start-rule token-stream)
  "Parse TOKEN-STREAM using START-RULE or signal a grammar failure."
  (multiple-value-bind (value remaining)
      (parse-rule start-rule token-stream)
    (if (parse-ok-p value)
        (values value remaining)
        (error "Grammar parse failure starting from rule ~S" start-rule))))
