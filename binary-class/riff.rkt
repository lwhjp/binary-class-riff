#lang racket/base

(require racket/class
         racket/contract/base
         binary-class)

(provide
 (contract-out
  [read-riff (->* () (input-port? (-> bytes? (or/c (subclass?/c riff%) #f))) (is-a?/c riff%))]
  [write-riff (->* ((is-a?/c riff%)) (output-port?) void?)])
 riff%
 riff:chunk%
 riff:list%
 fourcc
 pad/word)

(define (default-dispatch id) #f)

(define current-riff-dispatch (make-parameter default-dispatch))

(define (read-riff [in (current-input-port)]
                   [dispatch default-dispatch])
  (parameterize ([current-riff-dispatch dispatch])
    (read-value riff% in)))

(define (write-riff v [out (current-output-port)])
  (send v write out))

(define-binary-class riff%
  ([id fourcc]
   [size l4])
  #:dispatch
  (cond
    [((current-riff-dispatch) id)]
    [(or (bytes=? #"RIFF" id) (bytes=? #"LIST" id)) riff:list%]
    [else riff:chunk%]))
    

(define-binary-class riff:chunk% riff%
  ([data (pad/word (bytestring size))]))

(define-binary-class riff:list% riff%
  ([type fourcc]
   [chunks (binary
            (λ (in) (read-riff-list (+ (file-position in) (- size 4)) in))
            (λ (out v) (write-riff-list v out)))])
  (define/public (chunk-ref chunk-id . sub-ids)
    (define chunk
      (findf (λ (c) (bytes=? chunk-id (get-field id c))) chunks))
    (cond
      [(null? sub-ids) chunk]
      [(is-a? riff:list% chunk) (send chunk chunk-ref . (cdr sub-ids))]
      [else #f])))

(define (read-riff-list end in)
  (define riff-dispatch (current-riff-dispatch))
  (let next-chunk ()
    (define pos (file-position in))
    (cond
      [(> pos end) (error "invalid RIFF structure")]
      [(= pos end) '()]
      [else (cons (read-value riff% in) (next-chunk))])))

(define (write-riff-list chunks out)
  (for ([v (in-list chunks)])
    (send v write out)))

(define fourcc (bytestring 4))

(define (pad/word type)
  (binary
   (λ (in)
     (begin0
       (read-value type in)
       (unless (even? (file-position in))
         (read-byte in))))
   (λ (out v)
     (write-value type out v)
     (unless (even? (file-position out))
       (write-byte 0 out)))))
