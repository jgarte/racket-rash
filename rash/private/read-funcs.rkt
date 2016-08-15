#lang racket/base

(provide
 rash-read-syntax
 rash-read
 parse-at-reader-output
 )

(require (prefix-in scribble: scribble/reader))

(define (rash-read-syntax src in)
  (let ([at-output (scribble:read-syntax-inside src in)])
    (parse-at-reader-output at-output #:src src)))

(define (rash-read in)
  (syntax->datum (rash-read-syntax #f in)))

(define (parse-at-reader-output argl
                                #:src [src #f])
  (for/fold ([out-list '()])
            ([str-or-atout (syntax->list argl)])
    (if (string? (syntax->datum str-or-atout))
        (append
         out-list
         (rash-read-syntax-seq src (open-input-string (syntax->datum str-or-atout))))
        (append out-list (list str-or-atout)))))

(define (rash-read-syntax-seq src in)
  (let ([result (parameterize ([current-readtable line-readtable])
                  (read-syntax src in))])
    (if (equal? eof result)
        '()
        (cons result (rash-read-syntax-seq src in)))))

(define rash-newline-symbol '|%%rash-newline-symbol|)

(define read-newline
  (case-lambda
    [(ch port)
     rash-newline-symbol]
    [(ch port src line col pos)
     (datum->syntax #f rash-newline-symbol)]))

(define (ignore-to-newline port)
  (let ([out (read-char port)])
    (if (or (equal? out #\newline)
            (equal? out eof))
        rash-newline-symbol
        (ignore-to-newline port))))

(define read-line-comment
  (case-lambda
    [(ch port)
     (ignore-to-newline port)
     rash-newline-symbol]
    [(ch port src line col pos)
     (ignore-to-newline port)
     (datum->syntax #f rash-newline-symbol)]))

(define bare-line-readtable
  (make-readtable #f
                  #\newline 'terminating-macro read-newline
                  #\; 'terminating-macro read-line-comment
                  ;; take away the special meanings of characters
                  #\| #\a #f
                  #\. #\a #f
                  #\( #\a #f
                  #\) #\a #f
                  #\{ #\a #f
                  #\} #\a #f
                  #\[ #\a #f
                  #\] #\a #f
                  ))

(define line-readtable
  (scribble:make-at-readtable #:readtable bare-line-readtable))