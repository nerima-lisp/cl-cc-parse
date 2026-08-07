;;;; t/parse-boundary-test.lisp — module boundary tests for cl-cc-parse
;;;;
;;;; cl-cc's own suite covers reading and lowering against this system. What is
;;;; pinned here is the dependency closure, which is what this extraction was
;;;; for: parse was the last of php's and javascript's four dependencies still
;;;; inside the monorepo, and so the last reason either had to depend on cl-cc
;;;; as a whole.

(in-package :cl-cc-parse/test)

(defvar *parse-boundary-probe* nil)

(describe-sequential "cl-cc-parse dependency closure"
  (it "has its two declared dependencies present"
    (dolist (name '("CL-CC/AST" "CL-CC/BOOTSTRAP"))
      (expect (find-package name) :to-be-truthy)))

  (it "loads without the VM or anything downstream of it"
    ;; Reading and lowering produce an AST. Nothing here should need the VM,
    ;; the optimizer or code generation, and if that changed it would put
    ;; cl-cc-parse back inside the cycle this extraction removed.
    (dolist (name '("CL-CC/VM" "CL-CC/OPTIMIZE" "CL-CC/CODEGEN" "CL-CC/COMPILE"
                    "CL-CC/EXPAND" "CL-CC/TYPE"))
      (expect (find-package name) :to-be nil))))

(describe-sequential "cl-cc-parse public surface"
  (it "exports the entry points a consumer lowers source through"
    (dolist (name '("LOWER-SEXP-TO-AST"))
      (expect (nth-value 1 (find-symbol name :cl-cc/parse)) :to-be :external))))

(describe-sequential "lowering"
  (it "lowers a literal to an AST node"
    (let ((ast (cl-cc/parse:lower-sexp-to-ast 42)))
      (expect (typep ast 'cl-cc/ast:ast-node) :to-be-truthy)))

  (it "lowers a let into a binding form rather than a call"
    ;; LET is a special form, so it must not fall through to the call path --
    ;; the difference is invisible until something tries to walk the bindings.
    (let ((ast (cl-cc/parse:lower-sexp-to-ast '(let ((x 1)) x))))
      (expect (typep ast 'cl-cc/ast:ast-let) :to-be-truthy))))
(describe-sequential "parser read-time evaluation boundary"
  (it "ignores an ambient *read-eval* binding by default"
    (setf cl-cc-parse/test::*parse-boundary-probe* nil)
    (let ((signaled nil)
          (*read-eval* t))
      (handler-case
          (cl-cc/parse:parse-cl-source
           "#.(progn (setf cl-cc-parse/test::*parse-boundary-probe* t) 42)")
        (error ()
          (setf signaled t)))
      (expect signaled :to-be-truthy)
      (expect cl-cc-parse/test::*parse-boundary-probe* :to-be nil)))

  (it "requires an explicit opt-in for host read-time evaluation"
    (setf cl-cc-parse/test::*parse-boundary-probe* nil)
    (let ((*read-eval* nil))
      (cl-cc/parse:parse-cl-source
       "#.(progn (setf cl-cc-parse/test::*parse-boundary-probe* t) 42)"
       "trusted-source.lisp"
       :allow-read-eval t))
    (expect cl-cc-parse/test::*parse-boundary-probe* :to-be t)))
