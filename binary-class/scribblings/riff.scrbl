#lang scribble/manual

@(require (for-label racket/base
                     racket/class
                     racket/contract/base
                     binary-class
                     binary-class/riff))

@title{Resource Interchange File Format (RIFF)}

@defmodule[binary-class/riff]

This module provides utilities for reading and writing RIFF files.

@section{Reading and Writing}

@defproc*[([(read-riff [in input-port? (current-input-port)]) (is-a?/c riff%)]
           [(read-riff [in input-port?]
                       [dispatch (-> bytes? (or/c (subclass?/c riff%) #f))])
            (is-a?/c riff%)])]{
Reads RIFF data from @racket[in] and returns it.
If @racket[dispatch] is supplied, it must be a procedure accepting
a four-byte chunk ID, and returning a subclass of @racket[riff%]
or @racket[#f] if no special handling is required.
}

@defproc[(write-riff [v (is-a?/c riff%)] [out output-port? (current-output-port)]) void?]{
Writes the RIFF object @racket[v] to @racket[out].
}

@section{Binary Classes}

@defclass[riff% object% (binary<%>)]{
The base type for all RIFF data.
@defconstructor[([id bytes?]
                 [size exact-nonnegative-integer?])]
}

@defclass[riff:chunk% riff% ()]{
Represents a raw chunk.
@defconstructor/auto-super[([data bytes?])]
}

@defclass[riff:list% riff% ()]{
Represents a list chunk.
@defconstructor/auto-super[([type bytes?]
                            [chunks (listof (is-a?/c riff%))])]
}

@defthing[fourcc binary? #:value (bytestring 4)]{
A binary type for reading chunk IDs.
}

@defproc[(pad/word [type binary?]) binary?]{
Returns a binary type based on @racket[type], with padding to the nearest word.
}
