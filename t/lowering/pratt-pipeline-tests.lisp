;;;; tests/unit/parse/pratt-pipeline-tests.lisp — Pratt parser pipeline tests
;;;;
;;;; Tests: CST node source positions, parse-cl-source multiple forms,
;;;; parse-all-forms s-expression output, parse-source single form,
;;;; error recovery via cst-error, special form dispatch,
;;;; parse-and-lower pipeline, pratt-parse-expr, pratt-add-diagnostic,
;;;; and pratt-parse-list-until.

(in-package :cl-cc/parse/lowering/test)


;;; ─── CST Node Source Positions ───────────────────────────────────────────────

(it-sequential "parse-integer-byte-positions"
  (let ((node (parse-one-cst "42")))
    (expect (= 0 (cl-cc/parse/cst:cst-node-start-byte node)) :to-be-truthy)
    (expect (= 2 (cl-cc/parse/cst:cst-node-end-byte node)) :to-be-truthy)))

(it-sequential "parse-offset-byte-positions"
  (multiple-value-bind (nodes _diag)
      (cl-cc/parse/grammar:parse-cl-source "1 99")
    (declare (ignore _diag))
    (let ((second-node (second nodes)))
      (expect (= 2 (cl-cc/parse/cst:cst-node-start-byte second-node)) :to-be-truthy))))

;;; ─── parse-cl-source: Multiple Forms ────────────────────────────────────────

(it-sequential "parse-cl-source-basic-behavior multiple-forms"
  (destructuring-bind (source expected-count check-diagnostics-listp) (list "1 2 3" 3 nil)
    (multiple-value-bind (nodes diag)
      (cl-cc/parse/grammar:parse-cl-source source)
    (expect (= expected-count (length nodes)) :to-be-truthy)
    (when check-diagnostics-listp
      (expect (listp diag) :to-be-truthy)))))

(it-sequential "parse-cl-source-basic-behavior returns-diagnostics"
  (destructuring-bind (source expected-count check-diagnostics-listp) (list "42" 1 t)
    (multiple-value-bind (nodes diag)
      (cl-cc/parse/grammar:parse-cl-source source)
    (expect (= expected-count (length nodes)) :to-be-truthy)
    (when check-diagnostics-listp
      (expect (listp diag) :to-be-truthy)))))

(it-sequential "parse-cl-source-basic-behavior empty-string"
  (destructuring-bind (source expected-count check-diagnostics-listp) (list "" 0 t)
    (multiple-value-bind (nodes diag)
      (cl-cc/parse/grammar:parse-cl-source source)
    (expect (= expected-count (length nodes)) :to-be-truthy)
    (when check-diagnostics-listp
      (expect (listp diag) :to-be-truthy)))))

;;; ─── parse-all-forms: S-expression Output ───────────────────────────────────

(it-sequential "parse-all-forms-value-cases integer"
  (destructuring-bind (source pred) (list "42" (lambda (f) (= f 42)))
    (expect (funcall pred (parse-one-sexp source)) :to-be-truthy)))

(it-sequential "parse-all-forms-value-cases string"
  (destructuring-bind (source pred) (list "\"hello\"" (lambda (f) (string= f "hello")))
    (expect (funcall pred (parse-one-sexp source)) :to-be-truthy)))

(it-sequential "parse-all-forms-value-cases nil-list"
  (destructuring-bind (source pred) (list "()" (lambda (f) (null f)))
    (expect (funcall pred (parse-one-sexp source)) :to-be-truthy)))

(it-sequential "parse-all-forms-value-cases symbol"
  (destructuring-bind (source pred) (list "foo" (lambda (f) (string= "FOO" (symbol-name f))))
    (expect (funcall pred (parse-one-sexp source)) :to-be-truthy)))

(it-sequential "parse-all-forms-value-cases call"
  (destructuring-bind (source pred) (list "(+ 1 2)" (lambda (f) (and (eq '+ (car f)) (= 1 (cadr f)) (= 2 (caddr f)))))
    (expect (funcall pred (parse-one-sexp source)) :to-be-truthy)))

(it-sequential "parse-all-forms-value-cases quote"
  (destructuring-bind (source pred) (list "'foo" (lambda (f) (and (eq 'quote (car f)) (string= "FOO" (symbol-name (cadr f))))))
    (expect (funcall pred (parse-one-sexp source)) :to-be-truthy)))

(it-sequential "parse-all-forms-value-cases nested"
  (destructuring-bind (source pred) (list "(let ((x (+ 1 2))) (* x x))" (lambda (f) (and (eq 'let (car f)) (string= "X" (symbol-name (caaadr f))))))
    (expect (funcall pred (parse-one-sexp source)) :to-be-truthy)))

(it-sequential "parse-all-forms-multiple"
  (let ((forms (cl-cc/parse/grammar:parse-all-forms "(defun f (x) x) (f 1)")))
    (expect (= 2 (length forms)) :to-be-truthy)
    (expect (caar forms) :to-be 'defun)
    (expect (symbol-name (cadar forms)) :to-equal "F")))

;;; ─── parse-source: Single Form ───────────────────────────────────────────────

(it-sequential "parse-source-returns-one-form"
  (expect (= 99 (cl-cc/parse/grammar:parse-source "99")) :to-be-truthy))

(it-sequential "parse-source-errors-on-empty"
  (signals error (cl-cc/parse/grammar:parse-source "")))

;;; ─── Error Recovery via cst-error ───────────────────────────────────────────

(it-sequential "parse-unmatched-paren-adds-diagnostic"
  (multiple-value-bind (nodes diag)
      (cl-cc/parse/grammar:parse-cl-source "(+ 1")
    (declare (ignore nodes))
    (expect (not (null diag)) :to-be-truthy)))

;;; ─── Special Forms: sexp-head-to-kind Dispatch ───────────────────────────────

(it-sequential "parse-special-form-head-kind defun"
  (destructuring-bind (source expected-kind) (list "(defun f (x) x)" :defun)
    (let ((node (parse-one-cst source)))
    (expect (cl-cc/parse/cst:cst-node-kind node) :to-be expected-kind))))

(it-sequential "parse-special-form-head-kind let"
  (destructuring-bind (source expected-kind) (list "(let ((x 1)) x)" :let)
    (let ((node (parse-one-cst source)))
    (expect (cl-cc/parse/cst:cst-node-kind node) :to-be expected-kind))))

(it-sequential "parse-special-form-head-kind if"
  (destructuring-bind (source expected-kind) (list "(if t 1 2)" :if)
    (let ((node (parse-one-cst source)))
    (expect (cl-cc/parse/cst:cst-node-kind node) :to-be expected-kind))))

(it-sequential "parse-special-form-head-kind lambda"
  (destructuring-bind (source expected-kind) (list "(lambda (x) x)" :lambda)
    (let ((node (parse-one-cst source)))
    (expect (cl-cc/parse/cst:cst-node-kind node) :to-be expected-kind))))

(it-sequential "parse-special-form-head-kind unknown"
  (destructuring-bind (source expected-kind) (list "(my-fn a b)" :call)
    (let ((node (parse-one-cst source)))
    (expect (cl-cc/parse/cst:cst-node-kind node) :to-be expected-kind))))

;;; ─── parse-and-lower: Full Pipeline ─────────────────────────────────────────

(it-sequential "parse-and-lower-cases returns-list"
  (destructuring-bind (source pred) (list "(+ 1 2)" (lambda (asts) (and (listp asts) (not (null asts)))))
    (expect (funcall pred (cl-cc/parse/lowering:parse-and-lower source)) :to-be-truthy)))

(it-sequential "parse-and-lower-cases integer-ast-int"
  (destructuring-bind (source pred) (list "42" (lambda (asts) (cl-cc/ast:ast-int-p (first asts))))
    (expect (funcall pred (cl-cc/parse/lowering:parse-and-lower source)) :to-be-truthy)))

(it-sequential "parse-and-lower-cases multiple-3-forms"
  (destructuring-bind (source pred) (list "1 2 3" (lambda (asts) (= 3 (length asts))))
    (expect (funcall pred (cl-cc/parse/lowering:parse-and-lower source)) :to-be-truthy)))

;;; ─── pratt-parse-expr: Direct Tests ──────────────────────────────────────────

;;; ─── pratt-add-diagnostic: Direct Tests ─────────────────────────────────────

;;; ─── pratt-parse-list-until: Direct Tests ───────────────────────────────────

