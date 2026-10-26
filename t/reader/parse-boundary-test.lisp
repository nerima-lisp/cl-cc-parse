;;;; t/reader/parse-boundary-test.lisp — module boundary tests for cl-cc-parse
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
  (it "keeps the facade surface and records feature-only additions"
    (let* ((expected
             (with-open-file (stream
                              (asdf:system-relative-pathname
                               "cl-cc-parse"
                               "t/export-surface.txt"))
               (read stream)))
           (keep-records
             (remove-if-not (lambda (record) (eq (second record) :keep))
                            expected))
           (add-records
             (remove-if-not (lambda (record) (eq (second record) :add))
                            expected))
           (expected-names
             (sort (mapcar #'sixth keep-records) #'string<))
           (actual-names
             (sort (loop for symbol being the external-symbols of
                         (find-package :cl-cc/parse)
                         collect (symbol-name symbol))
                   #'string<)))
      (expect (length expected) :to-be 88)
      (expect (length keep-records) :to-be 86)
      (expect (length add-records) :to-be 2)
      (expect (equal actual-names expected-names) :to-be-truthy)
      (dolist (record expected)
        (destructuring-bind (kind action facade feature home name
                             &optional changelog-ref)
            record
          (expect kind :to-be :symbol)
          (multiple-value-bind (facade-symbol facade-status)
              (find-symbol name (string-upcase facade))
            (multiple-value-bind (feature-symbol feature-status)
                (find-symbol name (string-upcase feature))
              (expect feature-status :to-be :external)
              (expect (string-equal
                       (package-name (symbol-package feature-symbol))
                       home)
                     :to-be-truthy)
              (ecase action
                (:keep
                 (expect facade-status :to-be :external)
                 (expect (eq facade-symbol feature-symbol) :to-be-truthy))
                (:add
                 (expect facade-status :to-be nil)
                 (expect (and (stringp changelog-ref)
                              (search "CHANGELOG.md#" changelog-ref))
                         :to-be-truthy)))))))
      (dolist (entry '(("LEXER-TOKEN-P" "CL-CC/PARSE/READER")
                       ("LEXER-TOKEN-TYPE" "CL-CC/PARSE/READER")
                       ("LEXER-TOKEN-VALUE" "CL-CC/PARSE/READER")
                       ("MAKE-CST-TOKEN" "CL-CC/PARSE/CST")))
        (destructuring-bind (name feature) entry
          (multiple-value-bind (bootstrap-symbol bootstrap-status)
              (find-symbol name :cl-cc/bootstrap)
            (expect bootstrap-status :to-be :external)
            (multiple-value-bind (feature-symbol feature-status)
                (find-symbol name feature)
              (expect (member feature-status '(:external :inherited :internal))
                      :to-be-truthy)
              (expect (eq feature-symbol bootstrap-symbol) :to-be-truthy)
              (expect (string-equal
                       (package-name (symbol-package bootstrap-symbol))
                       "CL-CC/BOOTSTRAP")
                      :to-be-truthy)
              (expect (nth-value 1 (find-symbol name :cl-cc/parse))
                      :to-be nil))))))))

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
    (expect cl-cc-parse/test::*parse-boundary-probe* :to-be t))

  (it "allows stdlib host constants only through explicit parser opt-in"
    (let ((source
            (concatenate 'string
                         "(defconstant most-positive-fixnum #.(1- (expt 2 62))) "
                         "(defconstant most-negative-fixnum #.(- (expt 2 62)))"))
          (blocked nil))
      (let ((*read-eval* t))
        (handler-case
            (cl-cc/parse:parse-all-forms source)
          (error ()
            (setf blocked t))))
      (expect blocked :to-be-truthy)
      (let ((forms
              (cl-cc/parse:parse-all-forms
               source
               :allow-read-eval t)))
        (expect (length forms) :to-be 2)
        (expect (third (first forms)) :to-be (1- (expt 2 62)))
        (expect (third (second forms)) :to-be (- (expt 2 62)))))))
(describe-sequential "parser feature expressions"
  (it "parses keyword names in compound feature expressions within the deadline"
    (let ((forms nil)
          (timed-out nil))
      (handler-case
          (setf forms
                (sb-ext:with-timeout 5
                  (cl-cc/parse:parse-all-forms
                   "#+(or (not :gcl) :gcl) 42")))
        (sb-ext:timeout () (setf timed-out t)))
      (expect timed-out :to-be nil)
      (expect (equal forms (quote (42))) :to-be t)))
  (it "rejects empty feature names"
    (let ((rejected nil))
      (handler-case
          (cl-cc/parse:parse-all-forms "#+(or :) 42")
        (error () (setf rejected t)))
      (expect rejected :to-be t))))
