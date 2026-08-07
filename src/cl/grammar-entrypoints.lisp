(in-package :cl-cc/parse)

;;; ─── Top-Level Entry Points ──────────────────────────────────────────────────

(defun parse-cl-source (source &optional source-file &rest options)
  "Parse CL SOURCE string into CST nodes using the hand-written lexer and
   recursive descent parser. Returns (values cst-list diagnostics).

   SOURCE-FILE is retained as the first positional source location identifier.
   ALLOW-READ-EVAL is NIL by default, so a dynamic *READ-EVAL* binding cannot
   enable host read-time evaluation. Set ALLOW-READ-EVAL to true only for
   trusted source that deliberately uses #. host constants. The keyword may
   follow SOURCE-FILE or be supplied directly after SOURCE."
  (when (keywordp source-file)
    (push source-file options)
    (setf source-file nil))
  (destructuring-bind (&key (allow-read-eval nil)) options
    (let* ((tokens (lex-all source :allow-read-eval allow-read-eval))
           (ts (make-token-stream :tokens tokens
                                  :source source
                                  :source-file source-file))
           (forms nil))
      (loop until (ts-at-end-p ts)
            do (let ((form (parse-cl-form ts)))
                 (if form
                     (push form forms)
                     (return))))
      (values (nreverse forms)
              (nreverse (token-stream-diagnostics ts))))))

;;; ─── Public CL grammar entry points ──────────────────────────────────────────
;;;
;;; parse-cl-source is the CST-producing entry point for the hand-written CL
;;; grammar pipeline. Higher-level helpers build on top of this interface.
