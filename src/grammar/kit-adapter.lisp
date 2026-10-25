(in-package :cl-cc/parse/grammar)

(defun %utf8-character-width (character)
  (let ((code (char-code character)))
    (cond
      ((<= code #x7f) 1)
      ((<= code #x7ff) 2)
      ((<= code #xffff) 3)
      (t 4))))

(defun %byte-offset-to-character-offset (source byte-offset)
  (loop with bytes = 0
        with characters = 0
        for character across source
        while (< bytes byte-offset)
        do (incf bytes (%utf8-character-width character))
           (incf characters)
        finally (return characters)))

(defun %kit-token-vector (tokens &optional source)
  (coerce
   (loop for token in tokens
         for index from 0
         for start = (or (getf token :start-byte) index)
         for end = (or (getf token :end-byte) (1+ index))
         for start-position = (if source
                                  (%byte-offset-to-character-offset source start)
                                  start)
         for end-position = (if source
                                (%byte-offset-to-character-offset source end)
                                end)
         for value = (getf token :value)
         collect (cl-parser-kit:make-token
                  :type (getf token :type)
                  :text (if (stringp value) value (princ-to-string value))
                  :value token
                  :metadata (list :legacy-token token)
                  :start start-position
                  :end end-position))
   'vector))

(defun %legacy-token-value-parser (type)
  (cl-parser-kit:map-parser
   (cl-parser-kit:type-token type)
   (lambda (token)
     (getf (cl-parser-kit:token-value token) :value))))

(defun %legacy-token-parser (type value)
  (if (null value)
      (%legacy-token-value-parser type)
      (cl-parser-kit:map-parser
       (cl-parser-kit:satisfies-token
        (lambda (token)
          (let ((legacy-token (cl-parser-kit:token-value token)))
            (and (eql (cl-parser-kit:token-type token) type)
                 (equal (getf legacy-token :value) value))))
        :expected-name type)
       (lambda (token)
         (getf (cl-parser-kit:token-value token) :value)))))

(defun %legacy-many-parser (parser)
  (cl-parser-kit:many
   (%legacy-zero-progress-as-failure-parser
    (cl-parser-kit:attempt parser))))
(defun %legacy-zero-progress-as-failure-parser (parser)
  (let ((zero-progress-failure
          (cl-parser-kit:fail-parser
           "A repeated parser must consume input."
           :expected :progress)))
    (cl-parser-kit:make-parser
     :name :legacy-zero-progress-as-failure
     :fn (lambda (input position)
           (multiple-value-bind (ok value next result)
               (cl-parser-kit:run-parser parser input position)
             (if (and ok (= next position))
                 (cl-parser-kit:run-parser
                  zero-progress-failure input position)
                 (values ok value next result)))))))

(defun %legacy-many1-parser (parser)
  (cl-parser-kit:bind-parser
   (cl-parser-kit:attempt parser)
   (lambda (first)
     (cl-parser-kit:map-parser
      (%legacy-many-parser parser)
      (lambda (rest)
        (cons first rest))))))

(defun %legacy-option-parser (parser)
  (cl-parser-kit:option :opt-absent
                        (cl-parser-kit:attempt parser)))

(defun %run-legacy-kit-parser (parser stream)
  (let ((input (%kit-token-vector stream)))
    (multiple-value-bind (ok value next result)
        (cl-parser-kit:parse-tokens parser input)
      (declare (ignore result))
      (if ok
          (values value (nthcdr next stream))
          (values :fail nil)))))
