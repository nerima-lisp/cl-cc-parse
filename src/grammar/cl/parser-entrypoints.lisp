(in-package :cl-cc/parse/grammar)

;;; S-Expression Parser

(defun parse-source (source &key (allow-read-eval nil))
  "Parse SOURCE into one s-expression using the hand-written CL lexer.
ALLOW-READ-EVAL is NIL by default. Set it only for trusted source that
deliberately uses #. host constants."
  (let ((forms (parse-all-forms source :allow-read-eval allow-read-eval)))
    (when (null forms)
      (error "Empty source"))
    (first forms)))

(defun parse-all-forms (source &key (allow-read-eval nil))
  "Parse SOURCE into a list of all top-level s-expressions.
Uses the hand-written CL lexer and recursive-descent parser (no host reader).
ALLOW-READ-EVAL is NIL by default. Set it only for trusted source that
deliberately uses #. host constants."
  (multiple-value-bind (cst-list _diagnostics)
      (parse-cl-source source :allow-read-eval allow-read-eval)
    (declare (ignore _diagnostics))
    (mapcar #'cst-to-sexp cst-list)))
