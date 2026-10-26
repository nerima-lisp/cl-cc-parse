;;;; tests/unit/parse/cl/grammar-tokenstream-tests.lisp
;;;; Unit tests for src/parse/cl/grammar.lisp — Token Stream helpers
;;;;
;;;; Covers: token-stream struct (make-token-stream, predicates),
;;;;   ts-peek, ts-advance, ts-at-end-p, ts-peek-type, ts-token-value,
;;;;   ts-expect (success, EOF, type mismatch),
;;;;   %tok-to-cst, %make-list-cst,
;;;;   parse-cl-source (simple integer, symbol, list).

(in-package :cl-cc/parse/grammar/test)

;;; ─── Token construction helpers ──────────────────────────────────────────

(defun make-test-token (type value &optional (start 0) (end 1))
  "Build a lexer token through the public reader API for testing."
  (let ((token (first (cl-cc/parse/reader:lex-all "x"))))
    (setf (cl-cc/bootstrap:lexer-token-type token) type
          (cl-cc/bootstrap:lexer-token-value token) value
          (cl-cc/parse/reader:lexer-token-start-byte token) start
          (cl-cc/parse/reader:lexer-token-end-byte token) end)
    token))

(defun make-test-ts (token-list &optional (source ""))
  "Build a token-stream from a list of lexer-tokens."
  (cl-cc/parse/grammar::make-token-stream :tokens token-list :source source))

;;; ─── ts-peek ─────────────────────────────────────────────────────────────

(it-sequential "ts-peek-behavior"
  (let* ((tok (make-test-token :T-INT 42))
         (ts  (make-test-ts (list tok))))
    (expect (cl-cc/parse/grammar::ts-peek ts) :to-be tok)
    (expect (cl-cc/parse/grammar::ts-peek ts) :to-be tok))
  (expect (cl-cc/parse/grammar::ts-peek (make-test-ts nil)) :to-be-null))

;;; ─── ts-advance ──────────────────────────────────────────────────────────

(it-sequential "ts-advance-behavior"
  (let* ((t1  (make-test-token :T-INT 1))
         (t2  (make-test-token :T-INT 2))
         (ts  (make-test-ts (list t1 t2))))
    (let ((consumed (cl-cc/parse/grammar::ts-advance ts)))
      (expect consumed :to-be t1)
      (expect (cl-cc/parse/grammar::ts-peek ts) :to-be t2)))
  (expect (cl-cc/parse/grammar::ts-advance (make-test-ts nil)) :to-be-null))

;;; ─── ts-peek-type ────────────────────────────────────────────────────────

(it-sequential "ts-peek-type-behavior"
  (let* ((tok (make-test-token :T-IDENT 'foo))
         (ts  (make-test-ts (list tok))))
    (expect (cl-cc/parse/grammar::ts-peek-type ts) :to-be :T-IDENT))
  (expect (cl-cc/parse/grammar::ts-peek-type (make-test-ts nil)) :to-be-null))

;;; ─── ts-at-end-p ─────────────────────────────────────────────────────────

(it-sequential "ts-at-end-p-behavior"
  (expect (cl-cc/parse/grammar::ts-at-end-p (make-test-ts nil)) :to-be-truthy)
  (expect (cl-cc/parse/grammar::ts-at-end-p (make-test-ts (list (make-test-token :T-INT 1)))) :to-be-falsy)
  (expect (cl-cc/parse/grammar::ts-at-end-p (make-test-ts (list (make-test-token :T-EOF nil)))) :to-be-truthy))

;;; ─── ts-token-value ──────────────────────────────────────────────────────

(it-sequential "ts-token-value-behavior"
  (let* ((tok (make-test-token :T-INT 99))
         (ts  (make-test-ts (list tok))))
    (expect (= 99 (cl-cc/parse/grammar::ts-token-value ts)) :to-be-truthy))
  (expect (cl-cc/parse/grammar::ts-token-value (make-test-ts nil)) :to-be-null))

;;; ─── ts-expect ───────────────────────────────────────────────────────────

(it-sequential "ts-expect-behavior"
  (let* ((tok (make-test-token :T-INT 5))
         (ts  (make-test-ts (list tok))))
    (let ((result (cl-cc/parse/grammar::ts-expect ts :T-INT)))
      (expect result :to-be tok)
      (expect (cl-cc/parse/grammar::ts-at-end-p ts) :to-be-truthy)))
  (let* ((tok (make-test-token :T-IDENT 'x))
         (ts  (make-test-ts (list tok))))
    (cl-cc/parse/grammar::ts-expect ts :T-INT "ctx")
    (expect (> (length (cl-cc/parse/grammar::token-stream-diagnostics ts)) 0) :to-be-truthy))
  (let ((ts (make-test-ts nil)))
    (cl-cc/parse/grammar::ts-expect ts :T-INT "end")
    (expect (> (length (cl-cc/parse/grammar::token-stream-diagnostics ts)) 0) :to-be-truthy)))

;;; ─── %tok-to-cst ─────────────────────────────────────────────────────────

(it-sequential "tok-to-cst-converts-lexer-token"
  (let* ((tok (make-test-token :T-INT 7 0 3))
         (cst (cl-cc/parse/grammar::%tok-to-cst tok)))
    (expect (cl-cc/parse:cst-token-p cst) :to-be-truthy)
    (expect (cl-cc/parse/cst:cst-node-kind cst) :to-be :T-INT)
    (expect (= 7 (cl-cc/parse:cst-token-value cst)) :to-be-truthy)
    (expect (= 0 (cl-cc/parse:cst-node-start-byte cst)) :to-be-truthy)
    (expect (= 3 (cl-cc/parse:cst-node-end-byte cst)) :to-be-truthy)))

(it-sequential "tok-to-cst-returns-nil-for-nil-input"
  (expect (cl-cc/parse/grammar::%tok-to-cst nil) :to-be-null))

;;; ─── %make-list-cst ──────────────────────────────────────────────────────

(it-sequential "make-list-cst-creates-interior-with-kind-and-span"
  (let ((node (cl-cc/parse/grammar::%make-list-cst :defun '() 0 10)))
    (expect (cl-cc/parse:cst-interior-p node) :to-be-truthy)
    (expect (cl-cc/parse/cst:cst-node-kind node) :to-be :defun)
    (expect (= 0 (cl-cc/parse:cst-node-start-byte node)) :to-be-truthy)
    (expect (= 10 (cl-cc/parse:cst-node-end-byte node)) :to-be-truthy)))

(it-sequential "make-list-cst-stores-children"
  (let* ((child (cl-cc/parse/grammar::%tok-to-cst (make-test-token :T-INT 1)))
         (node  (cl-cc/parse/grammar::%make-list-cst :call (list child) 0 5)))
    (expect (= 1 (length (cl-cc/parse:cst-interior-children node))) :to-be-truthy)
    (expect (first (cl-cc/parse:cst-interior-children node)) :to-be child)))

;;; ─── parse-cl-source ─────────────────────────────────────────────────────

(it-sequential "parse-cl-source-non-empty-for-valid-forms"
  (dolist (src '("42" "foo" "(+ 1 2)"))
    (let ((result (cl-cc/parse:parse-cl-source src)))
      (expect (listp result) :to-be-truthy)
      (expect (> (length result) 0) :to-be-truthy))))

(it-sequential "parse-cl-source-empty-string-returns-list"
  (expect (listp (cl-cc/parse:parse-cl-source "")) :to-be-truthy))

(in-package :cl-cc/parse/grammar/test)

(it-sequential "grammar-parse-cl-source-cases diagnostics-list"
  (destructuring-bind (verify) (list (lambda ()
             (multiple-value-bind (cst-list diagnostics)
                 (cl-cc/parse:parse-cl-source "(+ 1 2)")
               (declare (ignore cst-list))
               (expect (listp diagnostics) :to-be-truthy))))
    (funcall verify)))

(it-sequential "grammar-parse-cl-source-cases empty-yields-nil"
  (destructuring-bind (verify) (list (lambda ()
             (multiple-value-bind (cst-list diagnostics)
                 (cl-cc/parse:parse-cl-source "")
               (declare (ignore diagnostics))
               (expect cst-list :to-be-null))))
    (funcall verify)))

(it-sequential "grammar-parse-cl-source-cases single-form-cst"
  (destructuring-bind (verify) (list (lambda ()
             (multiple-value-bind (cst-list diagnostics)
                 (cl-cc/parse:parse-cl-source "(+ 1 2)")
               (declare (ignore diagnostics))
               (expect (= 1 (length cst-list)) :to-be-truthy)
               (expect (cl-cc/parse/cst:cst-interior-p (first cst-list)) :to-be-truthy))))
    (funcall verify)))

(it-sequential "grammar-token-stream-cases eof-returns-nil"
  (destructuring-bind (verify) (list (lambda ()
             (let ((ts (cl-cc/parse/grammar::make-token-stream :tokens nil :source "")))
               (expect (cl-cc/parse/grammar::parse-cl-form ts) :to-be-null))))
    (funcall verify)))

(it-sequential "grammar-token-stream-cases empty-peek"
  (destructuring-bind (verify) (list (lambda ()
             (let ((ts (cl-cc/parse/grammar::make-token-stream :tokens nil :source "")))
               (expect (cl-cc/parse/grammar::ts-peek ts) :to-be-null)
               (expect (cl-cc/parse/grammar::ts-at-end-p ts) :to-be-truthy))))
    (funcall verify)))

(it-sequential "grammar-token-stream-cases struct-fields"
  (destructuring-bind (verify) (list (lambda ()
             (let ((ts (cl-cc/parse/grammar::make-token-stream :tokens nil :source "test")))
               (expect (cl-cc/parse/grammar::token-stream-p ts) :to-be-truthy)
               (expect (cl-cc/parse/grammar::token-stream-tokens ts) :to-be-null)
               (expect (cl-cc/parse/grammar::token-stream-source ts) :to-equal "test"))))
    (funcall verify)))
