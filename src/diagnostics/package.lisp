(defpackage :cl-cc/parse/diagnostics
  (:use :cl)
  (:export
   #:fix-it #:make-fix-it #:fix-it-text #:fix-it-span
   #:diagnostic #:make-diagnostic
   #:diagnostic-severity #:diagnostic-message #:diagnostic-span
   #:diagnostic-error-code #:diagnostic-fix-it
   #:parse-failure
   #:make-parse-error #:make-parse-warning
   #:byte-offset-to-line-col #:source-line-at
   #:format-diagnostic #:format-diagnostic-list
   #:*werror-p* #:*werror-categories* #:warning-as-error-p
   #:did-you-mean #:undefined-symbol-diagnostic
   #:diagnostic-notes #:maybe-promote-warning-diagnostic))
