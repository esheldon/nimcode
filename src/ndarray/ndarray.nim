# TODO:  many things, but first
#    - comparisons
#    - ufuncs for math functions
#         - do all in math module if possible
#         - some like pow, ^, mod, tan2, arctan2, fmod, hypot are special
#    - type conversion
#    - reduction over specific dimensions
#    - add slicing
#    - add ordering, e.g. row major vs col major

import sequtils
import strutils
import math

type
    # add of RootObj to make not final, for inheritance
    NDArray*[T] = object

        size: int              # size is product of all elements of dims
        dims: seq[int]         # array holding the size of each dimension
        ndim: int

        strides: seq[int]      # how many elements are jumped to get 
                               # to the next in each dimension

        data: seq[T]           # use 1-D sequence as backing

proc ensure_compatible_dims[T1,T2](a1: NDArray[T1], a2: NDArray[T2]) =
    if a1.ndim != a2.ndim:
        let mess="mismatched number of dimensions for +=: $1 != $2" % [$a2.ndim,$a1.ndim]
        raise newException(ValueError, mess)

    for i in 0..a2.ndim-1:
        if a1.dims[i] != a2.dims[i]:
            let mess="mismatched dimensions for +=: $1 != $2" % [$a2.dims,$a1.dims]
            raise newException(ValueError, mess)


#
# read-only field getters
#

proc len*[T](self: NDArray[T]): int {.inline.} =
    ## Get a copy of the array total size over all dimensions
    result=self.size

proc dims*[T](self: NDArray[T]): seq[int] {.inline.} =
    ## Get a copy of the array dimensions
    result=self.dims

proc ndim*[T](self: NDArray[T]): int {.inline.} =
    ## Get a copy of the number of dimensions
    result=self.ndim

proc strides*[T](self: NDArray[T]): seq[int] {.inline.} =
    ## Get a copy of the strides array
    result=self.strides




proc init*[T](self: var NDArray[T], dims: varargs[int]) =
    ## initialize the array to zeros.
    ##
    ## If data is already present, re-initialize

    let ndim = len(dims)

    newSeq(self.dims, ndim)
    newSeq(self.strides, ndim)
    self.ndim=ndim

    var size=1
    for i in 0..ndim-1:
        self.dims[i] = dims[i]
        size = size * dims[i]

    var total_stride=1
    for i in countdown(ndim-1,0):

        if i < ndim-1:
            total_stride *= dims[i+1]
        self.strides[i] = total_stride

    newSeq(self.data, size)
    self.size=size


proc newArray*[T](dims: varargs[int]): NDArray[T] =
    ## Get a new array filled with zeros
    result.init(dims)

proc zeros*[T](dims: varargs[int]): NDArray[T] =
    ## get a new array filled with zeros.
    result.init(dims)

proc ones*[T](dims: varargs[int]): NDArray[T] =
    ## get a new array filled with ones
    result.init(dims)

    for i in 0..<result.size:
        result.data[i] = T(1)

proc replicate*[T](val: T, dims: varargs[int]): NDArray[T] =
    ## get a new array filled with ones
    result.init(dims)

    for i in 0..<result.size:
        result.data[i] = val

proc arange*[T](dims: varargs[int]): NDArray[T] =
    ## get a new array filled with values from 0 to the number of elements
    result.init(dims)

    for i in 0..result.size-1:
        result.data[i] = T(i)

proc ravel*[T](orig: NDArray[T]): NDArray[T] =
    ## get a flattened version of the array, sharing the
    ## underlying data

    result.ndim=1
    result.size=orig.size

    newSeq(result.dims, 1)
    result.dims[0] = orig.size

    newSeq(result.strides, 1)
    result.strides[0] = 1

    shallowCopy(result.data, orig.data)

#
# reduction over elements
#

proc sum*[T](self: NDArray[T]): T {.inline.} =
    ## sum over elements in the array
    self.data.sum()

proc cumsum*[T](self: NDArray[T], output: var NDArray[T]) {.inline.} =
    ## cumulative sum over all elements
    ##
    ## returns a new array of the same type and length
    ensure_compatible_dims(self, output)

    var cs: T = 0

    for i in 0..self.len-1:
        cs += self.data[i]
        output.data[i] = cs

proc cumsum*[T](self: NDArray[T]): NDArray[T] {.inline.} =
    ## cumulative sum over elements in the array
    result.init(self.dims)
    cumsum(self, result)

proc prod*[T](self: NDArray[T]): T =
    ## product over elements in the array

    result=1
    for i in 0..self.len-1:
        result *= self.data[i]

proc cumprod*[T](self: NDArray[T], output: var NDArray[T]) {.inline.} =
    ## cumulative product over elements in the array

    ensure_compatible_dims(self, output)

    var ps : T = 1.0

    for i in 0..self.len-1:
        ps *= self.data[i]
        output.data[i] = ps

proc cumprod*[T](self: NDArray[T]): NDArray[T] {.inline.} =
    ## cumulative product over elements in the array
    result.init(self.dims)
    cumprod(self, result)



#
# getters
#

# specific dimensions
proc `[]`*[T](self: NDArray[T], i: int): auto =
    let ndim=self.ndim

    if ndim != 1:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 1 index" % $ndim)
    self.data[i]

proc `[]`*[T](self: NDArray[T], i, j: int): auto =
    let ndim=self.ndim

    if ndim != 2:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $ndim)
    self.data[
        i*self.strides[0] +
        j
    ]

proc `[]`*[T](self: NDArray[T], i, j, k: int): auto =
    let ndim=self.ndim

    if ndim != 3:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $ndim)
    self.data[
        i*self.strides[0] +
        j*self.strides[1] +
        k
    ]

proc `[]`*[T](self: NDArray[T], i, j, k, l: int): auto =
    let ndim=self.ndim

    if ndim != 4:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $ndim)

    self.data[
        i*self.strides[0] +
        j*self.strides[1] +
        k*self.strides[2] +
        l
    ]

proc `[]`*[T](self: NDArray[T], indices: varargs[int]): auto =
    ## general element get
    ##
    ## might be slower than the specific ones above but
    ## I haven't actually timed it

    let ndim=self.ndim
    let nind=len(indices)

    if ndim != nind:
        let mess="tried to index $1 dimensional array with $2 indices" % [$ndim, $nind]
        raise newException(IndexError, mess)

    var index=0
    for i in 0..ndim-1:
        index += self.strides[i]*indices[i]

    self.data[index]


proc `[]=`*[T,T2](self: var NDArray[T], indices: varargs[int], val: T2): auto =
    ## general element set
    ##
    ## The value must be convertible to the type of the array

    let ndim=self.ndim
    let nind=len(indices)

    if ndim != nind:
        let mess="tried to index $1 dimensional array with $2 indices" % [$ndim, $nind]
        raise newException(IndexError, mess)

    var index=0
    for i in 0..ndim-1:
        index += self.strides[i]*indices[i]

    self.data[index] = T(val)

#
#
# scalar array operations
#
#

# in place operators

proc `.=`*[T,T2](self: var NDArray[T], val: T2) {.inline.} =
    ## set all elements of an array equal to the input scalar
    let tval = T(val)

    for i in 0..self.size-1:
        self.data[i] = tval


proc `+=`*[T,T2](self: var NDArray[T], val: T2) {.inline.} =
    ## add a scalar to the array inplace
    let tval = T(val)

    for i in 0..self.size-1:
        self.data[i] += tval

proc `-=`*[T,T2](self: var NDArray[T], val: T2) {.inline.} =
    ## subtract a scalar from the array inplace
    let tval = T(val)

    for i in 0..self.size-1:
        self.data[i] -= tval

proc `*=`*[T,T2](self: var NDArray[T], val: T2) {.inline.} =
    ## multiply the array by a scalar inplace
    let tval = T(val)

    for i in 0..self.size-1:
        self.data[i] *= tval

proc `/=`*[T,T2](self: var NDArray[T], val: T2) {.inline.} =
    ## divide the array by a scalar inplace
    let tval = T(val)

    for i in 0..self.size-1:
        self.data[i] /= tval

# These make new arrays
proc `+`*[T,T2](self: NDArray[T], val: T2): NDArray[T] {.inline.} =
    ## get arr + constant
    result = self
    result += val

proc `+`*[T,T2](val: T2, self: NDArray[T]): NDArray[T] {.inline.} =
    ## get constant + arr
    result = self
    result += val

proc `-`*[T,T2](self: NDArray[T], val: T2): NDArray[T] {.inline.} =
    ## get arr - constant
    result = self
    result -= val

proc `-`*[T,T2](val: T2, self: NDArray[T]): NDArray[T] {.inline.} =
    ## get constant - arr
    result = self
    result -= val

proc `*`*[T,T2](self: NDArray[T], val: T2): NDArray[T] {.inline.} =
    ## get arr * constant
    result = self
    result *= val

proc `*`*[T,T2](val: T2, self: NDArray[T]): NDArray[T] {.inline.} =
    ## get constant * arr
    result = self
    result *= val

proc `/`*[T,T2](self: NDArray[T], val: T2): NDArray[T] {.inline.} =
    ## get arr / constant
    result = self
    result /= val

proc `/`*[T,T2](val: T2, self: NDArray[T]): NDArray[T] {.inline.} =
    ## get constant / arr
    result = self
    result /= val

#
#
# operations using other arrays
#
#

# in place operations

proc `+=`*[T,T2](self: var NDArray[T], other: NDArray[T2]) {.raises: [ValueError].} =
    ## add an array in place
    ensure_compatible_dims(self, other)

    for i in 0..self.size-1:
        self.data[i] += other.data[i]

proc `-=`*[T,T2](self: var NDArray[T], other: NDArray[T2]) {.raises: [ValueError].} =
    ## subtract an array in place

    ensure_compatible_dims(self, other)

    for i in 0..self.size-1:
        self.data[i] -= other.data[i]

proc `*=`*[T,T2](self: var NDArray[T], other: NDArray[T2]) {.raises: [ValueError].} =
    ## multiply an array in place

    ensure_compatible_dims(self, other)

    for i in 0..self.size-1:
        self.data[i] *= other.data[i]

proc `/=`*[T,T2](self: var NDArray[T], other: NDArray[T2]) {.raises: [ValueError].} =
    ## divide an array in place

    ensure_compatible_dims(self, other)

    for i in 0..self.size-1:
        self.data[i] /= other.data[i]


# making new arrays
#
# currently demand the arrays are of the same type until
# we can implement promotions restrictions
# otherwise, there is no clear way to choose the output type
# other than by order in the expression


# unary
proc `+`*[T](self: NDArray[T]): NDArray[T] {.inline.} =
    ## just a copy
    result = self

proc `-`*[T](self: NDArray[T]): NDArray[T] {.inline.} =
    ## negate all values
    result = self

    let minusone = T(-1.0)
    result *= minusone


proc `+`*[T](first, second: NDArray[T]): NDArray[T] {.inline.} =
    ## add two arrays to get a new array
    result = first
    result += second

proc `-`*[T](first, second: NDArray[T]): NDArray[T] {.inline.} =
    ## subtract two arrays to get a new array
    result = first
    result -= second

proc `*`*[T](first, second: NDArray[T]): NDArray[T] {.inline.} =
    ## multiply two arrays to get a new array
    result = first
    result *= second

proc `/`*[T](first, second: NDArray[T]): NDArray[T] {.inline.} =
    ## divide two arrays to get a new array
    result = first
    result /= second

#
#
# Inspired by https://github.com/unicredit/linear-algebra/blob/master/private/ufunc.nim
# make universal functions apply to an array
#
#

# single argument
template makeUFunc*(fname: expr) =
    # creating a new array
    proc fname*[T](self: NDArray[T]): NDArray[T] {.inline.} =
        result.init(self.dims)

        for i in 0..self.size-1:
            result.data[i] = fname(self.data[i])

    # copying into an existing array
    proc fname*[T](self: NDArray[T], output: var NDArray[T]) {.inline.} =

        ensure_compatible_dims(self, output)

        for i in 0..self.size-1:
            output.data[i] = fname(self.data[i])

makeUFunc(exp)
makeUFunc(ln)
makeUFunc(log10)
makeUFunc(log2)
makeUFunc(sqrt)
makeUFunc(cbrt)

makeUFunc(sin)
makeUFunc(cos)
makeUFunc(sinh)
makeUFunc(cosh)

makeUFunc(tan)
makeUFunc(tanh)

makeUFunc(arccos)
makeUFunc(arcsin)
makeUFunc(arctan)

makeUFunc(erf)
makeUFunc(erfc)

makeUFunc(lgamma)
makeUFunc(tgamma)

makeUFunc(trunc)
makeUFunc(floor)
makeUFunc(ceil)
makeUFunc(round)

makeUFunc(deg2rad)
makeUFunc(rad2deg)


#makeUFunc[float](exp)
#proc exp*[T](self: NDArray[T]): NDArray[T] {.inline.} =
#    result.init(self.dims)
#
#    for i in 0..self.size-1:
#        result.data[i] = exp(self.data[i])



proc `$`*[T](self: NDArray[T]): string =

    if self.ndim==2:
        var lines = newSeq[string]()

        for i in 0..self.dims[0]-1:
            var line = newSeq[string]()


            for j in 0..self.dims[1]-1:
                line.add( $self[i,j] )

            var tmp = "[" & line.join(", ") & "]"

            if i==0:
                tmp = "[" & tmp
            elif i==self.dims[0]-1:
                tmp = " " & tmp & "]"
            else:
                tmp = " " & tmp

            lines.add(tmp)

        result = lines.join("\n")
    else:
        result = $self.data
    #result = $self.data

