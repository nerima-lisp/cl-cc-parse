;;;; pratt.lisp — Language-agnostic Pratt + Recursive Descent engine
;;;;
;;;; Used by cl/grammar.lisp (CL) and php/grammar.lisp (PHP).
;;;; The pratt-context struct stores token-accessor functions so the same
;;;; engine works with lexer-token structs (CL) and token plists (PHP).

(in-package :cl-cc/parse/grammar)

;;; ─── Pratt Context ───────────────────────────────────────────────────────────

(defstruct pratt-context
  "Unified mutable parser context for Pratt+RecDescent parsing."
  (tokens      nil  :type list)
  (source      ""   :type string)
  (source-file nil  :type (or string null))
  (diagnostics nil  :type list)
  ;; Per-context NUD table: token-type keyword -> (lambda (ctx tok) -> cst-node)
  (nud-table   nil  :type (or hash-table null))
  ;; Per-context LED table: token-type keyword -> (cons binding-power (lambda (ctx left tok) -> cst-node))
  (led-table   nil  :type (or hash-table null))
  ;; Token accessor functions -- swap these for PHP vs CL
  (tok-type-fn  #'lexer-token-type       :type function)
  (tok-value-fn #'lexer-token-value      :type function)
  (tok-start-fn #'lexer-token-start-byte :type function)
  (tok-end-fn   #'lexer-token-end-byte   :type function))

;;; ─── Token Accessors ─────────────────────────────────────────────────────────

(defun pratt-tok-type (ctx tok)
  (when tok (funcall (pratt-context-tok-type-fn ctx) tok)))

(defun pratt-tok-value (ctx tok)
  (when tok (funcall (pratt-context-tok-value-fn ctx) tok)))

(defun pratt-tok-start (ctx tok)
  (when tok (funcall (pratt-context-tok-start-fn ctx) tok)))

(defun pratt-tok-end (ctx tok)
  (when tok (funcall (pratt-context-tok-end-fn ctx) tok)))

;;; ─── Stream Operations ──────────────────────────────────────────────────────

(defun pratt-peek (ctx)
  "Return current token without consuming."
  (car (pratt-context-tokens ctx)))

(defun pratt-peek-type (ctx)
  (pratt-tok-type ctx (pratt-peek ctx)))


(defun pratt-advance (ctx)
  "Consume and return current token."
  (let ((tok (car (pratt-context-tokens ctx))))
    (setf (pratt-context-tokens ctx) (cdr (pratt-context-tokens ctx)))
    tok))

(defun pratt-at-end-p (ctx)
  (let ((tok (pratt-peek ctx)))
    (or (null tok)
        (eq (pratt-tok-type ctx tok) :T-EOF))))

;;; ─── Diagnostics ────────────────────────────────────────────────────────────

(defun pratt-add-diagnostic (ctx message span &key (severity :error))
  "Push a diagnostic. Span is (start-byte . end-byte)."
  (declare (ignore severity))
  (push (make-parse-error message span
                          :source-file (pratt-context-source-file ctx))
        (pratt-context-diagnostics ctx)))

(defun pratt-expect (ctx expected-type &optional context)
  "Consume a token of EXPECTED-TYPE. Push diagnostic and return NIL on mismatch."
  (let ((tok (pratt-peek ctx)))
    (cond
      ((null tok)
       (pratt-add-diagnostic ctx
         (format nil "~@[~A: ~]unexpected end of input, expected ~A"
                 context expected-type)
         (cons 0 0))
       nil)
      ((eq (pratt-tok-type ctx tok) expected-type)
       (pratt-advance ctx))
      (t
       (pratt-add-diagnostic ctx
         (format nil "~@[~A: ~]expected ~A but got ~A"
                 context expected-type (pratt-tok-type ctx tok))
         (cons (pratt-tok-start ctx tok) (pratt-tok-end ctx tok)))
       nil))))

;;; ─── Core Pratt Loop ────────────────────────────────────────────────────────

;;; ─── List Parsing Helper ────────────────────────────────────────────────────

(defun %legacy-pratt-consumed (tokens remaining)
  (loop with tail = tokens
        for count from 0
        do (cond
             ((eq tail remaining)
              (return count))
             ((null tail)
              (error "Legacy Pratt handler returned a non-tail token list"))
             (t
              (setf tail (cdr tail))))))

(defun %pratt-kit-token-vector (ctx tokens)
  (let ((source (pratt-context-source ctx)))
    (coerce
     (loop for token in tokens
           for index from 0
           for start-byte = (or (pratt-tok-start ctx token) index)
           for end-byte = (or (pratt-tok-end ctx token) (1+ index))
           for value = (pratt-tok-value ctx token)
           collect (cl-parser-kit:make-token
                    :type (pratt-tok-type ctx token)
                    :text (if (stringp value) value (princ-to-string value))
                    :value token
                    :metadata (list :legacy-token token)
                    :start (%byte-offset-to-character-offset source start-byte)
                    :end (%byte-offset-to-character-offset source end-byte)))
     'vector)))

(defun %invoke-legacy-pratt-prefix (ctx tokens handler next)
  (let* ((token (nth (1- next) tokens))
         (remaining (nthcdr next tokens)))
    (setf (pratt-context-tokens ctx) remaining)
    (let ((value (funcall handler ctx token)))
      (values t value
              (+ next
                 (%legacy-pratt-consumed remaining
                                         (pratt-context-tokens ctx)))
              nil))))

(defun %invoke-legacy-pratt-led (ctx tokens handler left token next)
  (let ((remaining (nthcdr next tokens)))
    (setf (pratt-context-tokens ctx) remaining)
    (let ((value (funcall handler
                          ctx
                          left
                          (cl-parser-kit:token-value token))))
      (values t value
              (+ next
                 (%legacy-pratt-consumed remaining
                                         (pratt-context-tokens ctx)))
              nil))))

(defun %make-kit-pratt-table (ctx tokens)
  (let ((table (cl-parser-kit:make-pratt-table)))
    (when (pratt-context-nud-table ctx)
      (maphash
       (lambda (type handler)
         (cl-parser-kit:register-prefix-operator
          table type 0
          (lambda (token input next kit-table)
            (declare (ignore token input kit-table))
            (%invoke-legacy-pratt-prefix ctx tokens handler next))))
       (pratt-context-nud-table ctx)))
    (when (pratt-context-led-table ctx)
      (maphash
       (lambda (type entry)
         (cl-parser-kit:register-postfix-operator
          table type (car entry)
          (lambda (left token input next kit-table)
            (declare (ignore input kit-table))
            (%invoke-legacy-pratt-led
             ctx tokens (cdr entry) left token next))))
       (pratt-context-led-table ctx)))
    table))

(defun pratt-parse-expr (ctx &optional (min-bp 0))
  "Parse one expression using the registered legacy handlers and kit Pratt table."
  (let* ((tokens (pratt-context-tokens ctx))
         (input (%pratt-kit-token-vector ctx tokens))
         (table (%make-kit-pratt-table ctx tokens)))
    (multiple-value-bind (ok value next failure)
        (cl-parser-kit:parse-pratt
         input table :position 0 :min-binding-power (1+ min-bp))
      (declare (ignore failure))
      (if ok
          (progn
            (setf (pratt-context-tokens ctx) (nthcdr next tokens))
            value)
          (let* ((token (nth next tokens))
                 (start (if token (or (pratt-tok-start ctx token) 0) 0))
                 (end (if token (or (pratt-tok-end ctx token) 0) 0)))
            (setf (pratt-context-tokens ctx)
                  (if token
                      (cdr (nthcdr next tokens))
                      (nthcdr next tokens)))
            (when token
              (pratt-add-diagnostic
               ctx
               (format nil "unexpected token ~A in expression position"
                       (pratt-tok-type ctx token))
               (cons start end)))
            (make-cst-error :kind :error
                            :message "unexpected token"
                            :start-byte start
                            :end-byte end))))))

(defun pratt-parse-list-until (ctx end-type parse-fn)
  "Parse (PARSE-FN ctx)* until END-TYPE token or EOF.
   Consumes the END-TYPE token. Returns list of results."
  (let ((items nil))
    (loop
      (when (or (pratt-at-end-p ctx) (eq (pratt-peek-type ctx) end-type))
        (return))
      (let ((item (funcall parse-fn ctx)))
        (if item
            (push item items)
            (return))))
    (pratt-expect ctx end-type "list")
    (nreverse items)))

;;; ─── Token to CST Conversion ────────────────────────────────────────────────

(defun pratt-tok-to-cst (ctx tok)
  "Convert the current language's token to a cst-token."
  (when tok
    (make-cst-token :kind (pratt-tok-type ctx tok)
                    :value (pratt-tok-value ctx tok)
                    :start-byte (or (pratt-tok-start ctx tok) 0)
                    :end-byte (or (pratt-tok-end ctx tok) 0)
                    :source-file (pratt-context-source-file ctx)
                    :trivia (when (lexer-token-p tok) (lexer-token-trivia tok)))))
