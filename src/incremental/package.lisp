(defpackage :cl-cc/parse/incremental
  (:use :cl :cl-cc/bootstrap :cl-cc/parse/cst)
  (:export
   #:edit-operation #:make-edit-operation
   #:parse-incremental
   #:cache-lookup #:cache-store #:invalidate-parse-cache))
