(in-package :cl-cc/parse/grammar/test)

(defun make-pratt-adapter-context (tokens)
  (let* ((nud-table (make-hash-table :test #'eq))
         (led-table (make-hash-table :test #'eq))
         (context
           (make-pratt-context
            :tokens tokens
            :nud-table nud-table
            :led-table led-table
            :tok-type-fn (lambda (token) (getf token :type))
            :tok-value-fn (lambda (token) (getf token :value))
            :tok-start-fn (lambda (token) (getf token :start))
            :tok-end-fn (lambda (token) (getf token :end)))))
    (setf (gethash :integer nud-table)
          (lambda (ctx token)
            (declare (ignore ctx))
            (getf token :value))
          (gethash :minus nud-table)
          (lambda (ctx token)
            (declare (ignore token))
            (list '- (pratt-parse-expr ctx 30))))
    (flet ((binary-handler (operator binding-power)
             (cons binding-power
                   (lambda (ctx left token)
                     (declare (ignore token))
                     (list operator left
                           (pratt-parse-expr ctx binding-power))))))
      (setf (gethash :plus led-table) (binary-handler '+ 10)
            (gethash :times led-table) (binary-handler '* 20))
      context)))

(describe-sequential "cl-parser-kit Pratt adapter"
  (it "dispatches registered NUD and LED handlers with their binding powers"
    (let* ((context
             (make-pratt-adapter-context
              '((:type :minus :value "-")
                (:type :integer :value 2)
                (:type :times :value "*")
                (:type :integer :value 3)
                (:type :plus :value "+")
                (:type :integer :value 4)
                (:type :times :value "*")
                (:type :integer :value 5)
                (:type :plus :value "+")
                (:type :integer :value 6))))
           (result (pratt-parse-expr context)))
      (expect (hash-table-count (pratt-context-nud-table context)) :to-be 2)
      (expect (hash-table-count (pratt-context-led-table context)) :to-be 2)
      (expect (equal result '(+ (+ (* (- 2) 3) (* 4 5)) 6)) :to-be t)
      (expect (pratt-context-tokens context) :to-be nil))))