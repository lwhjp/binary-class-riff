#lang scribble/manual

@(require (for-label racket/base
                     racket/class
                     racket/contract/base
                     binary-class
                     binary-class/riff
                     binary-class/wave))

@title{WAVE File Format (WAV)}

@defmodule[binary-class/wave]

This module provides utilities for reading and writing WAVE files.

Some of the more advanced features of the format are not implemented;
let me know if you need them!

@section{Reading and Writing}

@defproc[(read-wave [in input-port? (current-input-port)]) wave?]{
Reads WAVE data from @racket[in] and returns it.
}

@defproc[(write-wave [wav wave?] [out output-port? (current-output-port)]) void?]{
Writes the WAVE object @racket[wav] to @racket[out].
}

@section{Utilities}

@defproc[(wave? [v any/c]) boolean?]{
Predicate for WAVE data. Equivalent to
@racket[(and (is-a? v riff:list%) (bytes=? #"WAVE" (get-field type v)))].
}

@defproc[(wave-bits [wav wave?]) exact-positive-integer?]{
Returns the number of bits per sample of @racket[wav].
}

@defproc[(wave-channels [wav wave?]) exact-positive-integer?]{
Returns the number of channels in @racket[wav].
}

@defproc[(wave-sample-rate [wav wave?]) exact-positive-integer?]{
Returns the sample rate of @racket[wav].
}

@defproc[(wave-format [wav wave?]) (is-a?/c wave:format%)]{
Returns the format chunk of @racket[wav]. An exception will be raised
if none is found.
}

@defproc[(in-wave-channel [wav wave?] [ch exact-nonnegative-integer?]) sequence?]{
Returns a sequence consisting of the samples of channel number @racket[ch]
in @racket[wav].
}

@defproc[(in-wave [wav wave?]) sequence?]{
Returns a sequence consisting of the samples of @racket[wav]. Each
element of the sequence has as many values as there are channels.
}

@section{Binary Classes}

@defclass[wave:format% riff% ()]{
A type representing the WAVE format chunk.
@defconstructor[([format-tag exact-nonnegative-integer?]
                 [channels exact-positive-integer?]
                 [samples-per-sec exact-positive-integer?]
                 [avg-bytes-per-sec exact-positive-integer?]
                 [block-align exact-positive-integer?]
                 [bits-per-sample exact-positive-integer?])]
}

@defclass[wave:format:extensible% wave:format% ()]{
Represents extensible format data.
@defconstructor/auto-super[([extension-size exact-nonnegative-integer?])]
}

@defclass[wave:format:extended% wave:format:extensible% ()]{
Represents extended format data.
@defconstructor/auto-super[([valid-bits-per-sample exact-nonnegative-integer?]
                            [channel-mask exact-nonnegative-integer?]
                            [sub-format bytes?])]
}
