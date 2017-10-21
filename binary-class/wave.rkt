#lang racket/base

(require racket/class
         racket/contract/base
         racket/math
         racket/sequence
         binary-class
         "riff.rkt")

(provide
 (contract-out
  [wave? predicate/c]
  [read-wave (->* () (input-port?) wave?)]
  [write-wave (->* (wave?) (output-port?) void?)]
  [wave-bits (-> wave? exact-positive-integer?)]
  [wave-channels (-> wave? exact-positive-integer?)]
  [wave-sample-rate (-> wave? exact-positive-integer?)]
  [wave-format (-> wave? (is-a?/c wave:format%))]
  [in-wave-channel (-> wave? exact-nonnegative-integer? sequence?)]
  [in-wave (-> wave? sequence?)])
 wave:format%
 wave:format:extensible%
 wave:format:extended%)

; TODO: support reading data on demand

(define (wave? v)
  (and (is-a? v riff:list%)
       (bytes=? #"WAVE" (get-field type v))))

(define (read-wave [in (current-input-port)])
  (read-riff in wave-dispatch))

(define (write-wave v [out (current-output-port)])
  (write-riff v out))

(define-binary-class wave:format% riff%
  ([format-tag l2]
   [channels l2]
   [samples-per-sec l4]
   [avg-bytes-per-sec l4]
   [block-align l2]
   [bits-per-sample l2])
  #:dispatch
  (if (> size 16) wave:format:extensible% this%))

(define-binary-class wave:format:extensible% wave:format%
  ([extension-size l2])
  #:dispatch
  (case extension-size
    [(0) this%]
    [(22) wave:format:extended%]
    [else (error "invalid wave format")]))

(define-binary-class wave:format:extended% wave:format:extensible%
  ([valid-bits-per-sample l2]
   [channel-mask l4]
   [sub-format (bytes 16)]))

(define (wave-dispatch id)
  (case id
    [(#"fmt ") wave:format%]
    [else #f]))

(define (wave-format wav)
  (cond
    [(send wav chunk-ref #"fmt ")]
    [else (error "wave has no format information")]))

(define-values (wave-channels wave-sample-rate wave-bits)
  (let ([make-ref (λ (field)
                    (λ (wav)
                      (dynamic-get-field field (wave-format wav))))])
    (apply values (map make-ref '(channels samples-per-sec bits-per-sample)))))

(define (in-wave-channel wav ch)
  (unless (< ch (wave-channels wav))
    (error 'in-wave-channel "channel number out of range: ~a" ch))
  (define data-chunk (send wav chunk-ref #"data"))
  (unless data-chunk
    (error 'in-wave-channel "wave has no samples"))
  (define fmt (wave-format wav))
  (define bits (get-field bits-per-sample fmt))
  (define bytes-per-sample (exact-ceiling (/ bits 8)))
  (define samples (get-field data data-chunk))
  (define signed? (> bits 8))
  (sequence-map
   (λ (pos)
     (integer-bytes->integer samples signed? #f pos (+ pos bytes-per-sample)))
   (in-range (* ch bytes-per-sample)
             (bytes-length samples)
             (get-field block-align fmt))))

(define (in-wave wav)
  (apply
   in-parallel
   (map (λ (ch) (in-wave-channel wav ch))
        (build-list (wave-channels wav) values))))
