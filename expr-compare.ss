; © 2018-2019 Daxuan Shu



;; summary expressions without thinking about bound variables. Dealing with base conditions and using tail recursive
;; to parse through the two input expressions x and y
(define (prefinished-summary-expr x y)
	(cond
		;;base condition 1: structural equivalence?
		( (equal? x y) x) 
		
		;;base condition 2: Not structural equivalence and at least one of x and y is not a list
		( (not (and (list? x) (list? y) ) ) (if (and (boolean? x) (boolean? y) ) ;; if x and y are both boolean variables, it has to be x = #t, y= #f
											  	(if x '% '(not %) ) 			 ;; or x = #f, y = #t since the condition has passed base condition 1.
											  	(list 'if '% x y)	
										  	)
		) 
		
		;;base condition 3: x and y are both lists and not structural equivalence and different length
		( (not (equal? (length x) (length y) ) ) (list 'if '% x y) )
		
		;;base condition 4: different leading keywords (not different leading variables)
		((and (or (member (car x) '(if let quote lambda)) (member (car y) '(if let quote lambda)) );;avoid counting leading variables
			 (not (equal? (car x) (car y) ) ))
			 (list 'if '% x y) 
		)

		;;base condition 5: leading keywords are quote or '
		( (or (equal? (car x) 'quote) (equal? (car y) 'quote) ) (list 'if '% x y))

		;; tail recursive
		(else (cons (prefinished-summary-expr (car x) (car y) ) (prefinished-summary-expr (cdr x) (cdr y) ) ) )
	)
)

(define (get-let-bindings l1 l2 b)
	(cond
		;;base condition 1: at least of the x and y's bindings is empty, then simply pass through binding list b 
		((or (empty? l1) (empty? l2)) b)
		;;base condition 2: The length of the bindings of x and y are different, then it is impossible to have bound variables here.
		;;((not (equal? (length l1) (length l2)) ) b)
		;;base condition 3: At least one of the leading element is keyword or a list. It is not bound variable.
		((or 
			(member (car (car l1)) '(if let quote lambda))
			(member (car (car l2)) '(if let quote lambda))
			(list? (car (car l1)))
			(list? (car (car l1))))
		 (get-let-bindings (cdr l1) (cdr l2) b)
		)
		;;base condition 4: The leading varibales of the two bindings are the same. It is not bound variable and jump over it.
		((equal? (car (car l1)) (car (car l2))) (get-let-bindings (cdr l1) (cdr l2) b))
		
		;;Otherwise, we found a bound variable,say a!b, and add it into binding list b. b has the list format '((a b)) instead of empty '().
		;;Meanwhile, recursively call the function to keep looking through the remaining expressions.
		(else (get-let-bindings (cdr l1) (cdr l2) (cons (cons (car (car l1)) (cons (car (car l2)) empty)) b))) 
	)

)



;; The get-lambda-binding funtion is similar to function get-let-bindings 

(define (get-lambda-bindings l1 l2 b)
	(cond
		;;base condition 1: at least of the x and y's bindings is empty, then simply pass through binding list b 
		((or (empty? l1) (empty? l2)) b)
		;;base condition 2: The length of the bindings of x and y are different, then it is impossible to have bound variables here.
		((not (equal? (length l1) (length l2)) ) b)
		;;base condition 3: At least one of the leading element is keyword or a list. It is not bound variable.
		((or (member (car l1) '(if let quote lambda))
			(member  (car l2) '(if let quote lambda))   
			(list? (car  l1))
			(list? (car  l2)))
		 (get-lambda-bindings (cdr l1) (cdr l2) b)
		)
		;;base condition 4: The leading varibales of the two bindings are the same. It is not bound variable and jump over it.
		((equal? (car l1) (car l2)) (get-lambda-bindings (cdr l1) (cdr l2) b))
		
		;;Otherwise, we found a bound variable,say a!b, and add it into binding list b. b has the list format '((a b)) instead of empty '().
		;;Meanwhile, recursively call the function to keep looking through the remaining expressions.
		(else (get-lambda-bindings (cdr l1) (cdr l2) (cons (cons (car l1) (cons (car l2) empty)) b))) 
	)

)

(define (get-all-bindings x y b)
	(cond
		;;base condition 1:structural equivalence?
		((equal? x y) b)

		;;base condition 2:Not structural equivalence and at least one of x and y is not a list
		((not (and (list? x)(list? y))) b) ;; if at least one of x and y is not a list, then simply pass through binding list b.
		
		;;base condition 3:x and y are both lists and not structural equivalence and different length
		( (not (equal? (length x) (length y) ) ) b )

		;;base condition 4:leading keywords are both let 
		((and (equal? (car x) 'let) (equal? (car y) 'let)) 
		 (append (append (get-let-bindings (cadr x) (cadr y) empty) ;; get the bound variables inside the bindings after the keyword let
						 (get-all-bindings (cadr x) (cadr y) empty)) ;; in case there are nested bound variables inside the body of let
		 		 (append (get-all-bindings (cdr x) (cdr y) b) b) ;; recursively call the function to append further bound variables to the binding list b.	
		 )
		)

		;;base condition 5: leading keywords are both lamda, similar to condition 4.
		((and (equal? (car x) 'lambda) (equal? (car y) 'lambda)) 
		 (append (append (get-lambda-bindings (cadr x) (cadr y) empty) ;; get the bound variables inside the bindings after the keyword lambda
						 (get-all-bindings (cadr x) (cadr y) empty)) ;; in case there are nested bound variables inside the body of lamda
		 		 (append (get-all-bindings (cdr x) (cdr y) b) b) ;; recursively call the function to append further bound variables to the binding list b.	
		 )
		)

		;;base condition 6: Dealing with the case when both x and y's car parts are lists . e.g. (expr-compare '((lambda (a b) (f a b)) 1 2) '((lambda (a c) (f c a)) 1 2))
  		;; 																					⇒ ((lambda (a b!c) (f (if % a b!c) (if % b!c a)))1 2)
		( (and (list? (car x)) (list? (car y)))
     	  (append (get-all-bindings (car x) (car y) empty) (get-all-bindings (cdr x) (cdr y) b))
     	)
		;; tail recursive
		(else (get-all-bindings (cdr x) (cdr y) b)) ;; recursively call the funtion to parse the expressions from the beginning to the end.

		
	)
)



(define (combine-binding a b)
  (string->symbol (string-append (symbol->string a) "!" (symbol->string b)))
)

;;(cons 'a (cons 'b empty))
(define (is-binding a b bindings)
	(member (cons (cons a(cons b empty)) empty) bindings) ;; anything other than #f is #t in boolean
)


(define (replacer expr bindings)
  (cond
  	((empty? expr) expr)
    ((not (list? expr)) expr)
    ((and
      (equal? (length expr) 4)
      (and (equal? (car expr) 'if) (equal? (cadr expr) '%))
      (and (is-binding (caddr expr) (cadddr expr) bindings))
    ) (combine-binding (caddr expr) (cadddr expr)))
    (else
         (cons (replacer (car expr) bindings) (replacer (cdr expr) bindings)))
  )
)

(define (expr-compare x y)
  (replacer (prefinished-summary-expr x y) (get-all-bindings x y empty))
)

(define (test-expr-compare x y)
  (and (equal? (eval x) (eval (list 'let '((% #t)) (expr-compare x y))))
       (equal? (eval y) (eval (list 'let '((% #f)) (expr-compare x y))))
))



(define test-expr-x 
	'(list
		12 
		12
  		#t
  		#f
  		#t
  		#f
  		1
  		(quote (1 4 2))
	)
)

(define test-expr-y 
	'(list
		12
		20
		#t
		#f
		#f
		#t
		'(cons 1 2)
		(quote (6 5 8))
  	)
)