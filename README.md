# Paul-Eggert-s-Homework-Summary
produces a difference summary of where the two Scheme expressions are the same and where they differ.

Sample Test Cases:

(expr-compare 12 12)  ⇒  12
(expr-compare 12 20)  ⇒  (if % 12 20)
(expr-compare #t #t)  ⇒  #t
(expr-compare #f #f)  ⇒  #f
(expr-compare #t #f)  ⇒  %
(expr-compare #f #t)  ⇒  (not %)
(expr-compare 'a '(cons a b))  ⇒  (if % a (cons a b))
(expr-compare '(cons a b) '(cons a b))  ⇒  (cons a b)
(expr-compare '(cons a b) '(cons a c))  ⇒  (cons a (if % b c))
(expr-compare '(cons (cons a b) (cons b c))
              '(cons (cons a c) (cons a c)))
  ⇒ (cons (cons a (if % b c)) (cons (if % b a) c))
(expr-compare '(cons a b) '(list a b))  ⇒  ((if % cons list) a b)
(expr-compare '(list) '(list a))  ⇒  (if % (list) (list a))
(expr-compare ''(a b) ''(a c))  ⇒  (if % '(a b) '(a c))
(expr-compare '(quote (a b)) '(quote (a c)))  ⇒  (if % '(a b) '(a c))
(expr-compare '(quoth (a b)) '(quoth (a c)))  ⇒  (quoth (a (if % b c)))
(expr-compare '(if x y z) '(if x z z))  ⇒  (if x (if % y z) z)
(expr-compare '(if x y z) '(g x y z))
  ⇒ (if % (if x y z) (g x y z))
(expr-compare '(let ((a 1)) (f a)) '(let ((a 2)) (g a)))
  ⇒ (let ((a (if % 1 2))) ((if % f g) a))
(expr-compare '(let ((a c)) a) '(let ((b d)) b))
  ⇒ (let ((a!b (if % c d))) a!b)
(expr-compare ''(let ((a c)) a) ''(let ((b d)) b))
  ⇒ (if % '(let ((a c)) a) '(let ((b d)) b))
(expr-compare '(+ #f (let ((a 1) (b 2)) (f a b)))
              '(+ #t (let ((a 1) (c 2)) (f a c))))
  ⇒ (+
     (not %)
     (let ((a 1) (b!c 2)) (f a b!c)))
(expr-compare '((lambda (a) (f a)) 1) '((lambda (a) (g a)) 2))
  ⇒ ((lambda (a) ((if % f g) a)) (if % 1 2))
(expr-compare '((lambda (a b) (f a b)) 1 2)
              '((lambda (a b) (f b a)) 1 2))
  ⇒ ((lambda (a b) (f (if % a b) (if % b a))) 1 2)
(expr-compare '((lambda (a b) (f a b)) 1 2)
              '((lambda (a c) (f c a)) 1 2))
  ⇒ ((lambda (a b!c) (f (if % a b!c) (if % b!c a)))
     1 2)
(expr-compare '(let ((a (lambda (b a) (b a))))
                 (eq? a ((lambda (a b) (let ((a b) (b a)) (a b)))
                         a (lambda (a) a))))
              '(let ((a (lambda (a b) (a b))))
                 (eqv? a ((lambda (b a) (let ((a b) (b a)) (a b)))
                          a (lambda (b) a)))))
  ⇒ (let ((a (lambda (b!a a!b) (b!a a!b))))
      ((if % eq? eqv?)
       a
       ((lambda (a!b b!a) (let ((a (if % b!a a!b) (b (if % a!b b!a))) (a b)))
        a (lambda (a!b) (if % a!b a))))))
