# TODO:  many things, but first
#    - using a reference type for the main array means they could
#      be packed into tuples
#    - make sure all array operations are using the iterators
#    - figure out how to implement type classes, so functions like
#      zeros only work for numerical data, or some how can
#      be adapted by type class
#    - comparisons
#       - some we can't seem to override, e.g. !=
#    - where
#    - ufuncs for math functions
#         - do all in math module if possible
#         - ^,pow are working but without error checking
#    - type conversion: multiply an integer by a float, we need to get a float back
#    - reduction over specific dimensions
#    - add slicing, including things like a[5] producing a new ndim-1 dim array
#    - add ordering, e.g. row major vs col major
#    ? allow strides that are by byte rather than by count
#        - this would faciliate things similar to numpy record arrays
#        - would require casting the data
#    - add div (integer division)
#    - add mod, integer modulo operation
#    - add shifts for integers

import strutils
import math

const rowMajor* = 1
const colMajor* = 2

type
    # We could use this for consistency with linalg package
    # but it currently gives warnings
    #OrderType* = enum
    #    rowMajor = 101,
    #    colMajor = 102

    # add of RootObj to make not final, for inheritance
    NDArray*[T] = object

        order: int

        size: int              # size is product of all elements of dims
        dims: seq[int]         # array holding the size of each dimension
        ndim: int

        strides: seq[int]      # how many elements are jumped to get 
                               # to the next in each dimension

        data: seq[T]           # use 1-D sequence as backing


proc ensure_compatible_dims[T1,T2](a1: NDArray[T1], a2: NDArray[T2]) =
    ## private proc to check dimensions are compatible
    if a1.ndim != a2.ndim:
        let mess="mismatched number of dimensions for +=: $1 != $2" % [$a2.ndim,$a1.ndim]
        raise newException(ValueError, mess)

    for i in 0..a2.ndim-1:
        if a1.dims[i] != a2.dims[i]:
            let mess="mismatched dimensions for +=: $1 != $2" % [$a2.dims,$a1.dims]
            raise newException(ValueError, mess)

#
# private iterators for stride and order aware access
# to the underlying private 1-d sequence
#

iterator indices1d[T](self: NDArray[T]): int {.inline.} =
    ## iterator for the 1-d indices into an array

    let L = len(self)

    if self.order == rowMajor:
        # fast version
        var i=0
        while i < self.size:
            yield i
            inc(i)
            assert(len(self) == L, "seq modified while iterating over it")
    else:
        var i = 0

        var current_indices=newSeq[int]( self.ndim )
        while i < (self.size-1):

            i=0
            for idim in 0..<self.ndim:
                i += current_indices[idim]*self.strides[idim]
            yield i
            assert(len(self) == L, "seq modified while iterating over it")

            for idim in countdown(self.ndim-1,0):
                if current_indices[idim] == (self.dims[idim]-1):
                    # reset this dim but continue to the next earliest
                    current_indices[idim] = 0
                else:
                    current_indices[idim] += 1
                    break

proc makeIndices1d[T](self: NDArray[T]): NDArray[T] =
    ## make an array of indices into the underlying 1d sequence
    ## this is just a copy from the iterator indices1d
    result.init(self.size)

    for i in indices1d(self):
        result[i] = i

iterator izip1d[S, T](a1: NDArray[S], a2: NDArray[T]): tuple[a, b: int] {.inline.} =
    ## iterator to return 1-d indices into two arrays together
    ## this is stride and order aware
    ##
    ## this is not user-facing because the underlying 1-d sequence
    ## is not user facing

    ensure_compatible_dims(a1, a2)

    let L = len(a1)

    if a1.order == a2.order:
        var i = 0
        while i < L:
            yield (i, i)
            inc(i)

            assert(len(a1) == L, "array modified while iterating over it")
            assert(len(a2) == L, "array modified while iterating over it")

    else:

        var
          i1 = 0
          i2 = 0
          current_indices=newSeq[int]( a1.ndim )

        while i1 < (a1.size-1):

            i1=0
            i2=0
            for idim in 0..<a1.ndim:
                i1 += current_indices[idim]*a1.strides[idim]
                i2 += current_indices[idim]*a2.strides[idim]

            yield (i1, i2)

            assert(len(a1) == L, "array modified while iterating over it")
            assert(len(a2) == L, "array modified while iterating over it")

            for idim in countdown(a1.ndim-1,0):
                if current_indices[idim] == (a1.dims[idim]-1):
                    # reset this dim but continue to the next earliest
                    current_indices[idim] = 0
                else:
                    current_indices[idim] += 1
                    break


iterator izip1d[S, T, U](a1: NDArray[S], a2: NDArray[T], a3: NDArray[U]): tuple[a,b,c: int] {.inline.} =
    ## iterator to return 1-d indices into three arrays together
    ## this is stride and order aware
    ##
    ## this is not user-facing because the underlying 1-d sequence
    ## is not user facing

    ensure_compatible_dims(a1, a2)
    ensure_compatible_dims(a1, a3)

    let L = len(a1)

    if a1.order == a2.order and a1.order == a3.order:
        var i = 0
        while i < L:
            yield (i, i, i)
            inc(i)

            assert(len(a1) == L, "array modified while iterating over it")
            assert(len(a2) == L, "array modified while iterating over it")
            assert(len(a3) == L, "array modified while iterating over it")

    else:

        var
          i1 = 0
          i2 = 0
          i3 = 0
          current_indices=newSeq[int]( a1.ndim )

        while i1 < (a1.size-1):

            i1=0
            i2=0
            i3=0
            for idim in 0..<a1.ndim:
                i1 += current_indices[idim]*a1.strides[idim]
                i2 += current_indices[idim]*a2.strides[idim]
                i3 += current_indices[idim]*a3.strides[idim]

            yield (i1, i2, i3)

            assert(len(a1) == L, "array modified while iterating over it")
            assert(len(a2) == L, "array modified while iterating over it")
            assert(len(a3) == L, "array modified while iterating over it")

            for idim in countdown(a1.ndim-1,0):
                if current_indices[idim] == (a1.dims[idim]-1):
                    # reset this dim but continue to the next earliest
                    current_indices[idim] = 0
                else:
                    current_indices[idim] += 1
                    break



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

proc order*[T](self: NDArray[T]): int {.inline.} =
    ## Get a copy of the strides array
    result=self.order


proc calc_strides(dims: seq[int]): seq[int] =
    let ndim = len(dims)
    newSeq(result, ndim)

    var total_stride=1
    for i in countdown(ndim-1,0):

        if i < ndim-1:
            total_stride *= dims[i+1]
        result[i] = total_stride


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

    self.order = rowMajor
    self.strides = calc_strides(self.dims)

    #var total_stride=1
    #for i in countdown(ndim-1,0):
    #    if i < ndim-1:
    #        total_stride *= dims[i+1]
    #    self.strides[i] = total_stride

    newSeq(self.data, size)
    self.size=size

proc fromSeq*[T](s: seq[T], copy: bool=true): NDArray[T] =
    ## Get a new array filled with a copy of the input seq

    if copy:
        result.init(s.len)

        for i,val in pairs(s):
            result.data[i] = val
    else:
        result.size=s.len
        result.dims = @[result.size]
        result.strides = @[1]

        result.ndim=1
        result.dims[0] = s.len
        result.strides[0] = 1

        shallowCopy(result.data, s)

proc shareData*[T](a: NDArray[T]): NDArray[T] =
    ## Get a new array that shares data with the input array
    shallowCopy(result, a)

proc strings*(dims: varargs[int]): NDArray[string] =
    ## get a new array filled with empty strings
    ## do not use zeros[string], as it fills with nil
    result.init(dims)

    for i in 0..<result.len:
        result.data[i] = ""

proc zeros*[T](dims: varargs[int]): NDArray[T] =
    ## get a new array filled with zeros.
    result.init(dims)

proc ones*[T](dims: varargs[int]): NDArray[T] =
    ## get a new array filled with ones
    result.init(dims)

    for i in 0..<result.size:
        result.data[i] = T(1)

proc replicate*[T](val: T, dims: varargs[int]): NDArray[T] =
    ## get a new array filled with the specified value
    result.init(dims)

    for i in 0..<result.size:
        result.data[i] = val

proc arange*[T](n: int): NDArray[T] =
    ## get a new array filled with values from 0 to n-1
    result.init(n)

    for i in 0..result.size-1:
        result.data[i] = T(i)

proc arange*[T](start: int, stop: int): NDArray[T] =
    ## get a new array filled with the specified range of values
    ## following nim style, the end is inclusive

    var ntot = stop-start + 1

    if ntot <= 0:
        ntot = 0

    result.init(ntot)

    if ntot > 0:
        for i in 0..<ntot:
            result.data[i] = T(i+start)

proc arange*[T](rng: Slice[int]): NDArray[T] =
    ## get a new array filled with the specified range of values

    result = arange[T](rng.a, rng.b)

proc linspace*[T](start, stop: T, npts: int): NDArray[T] =
    ## TODO: deal with npts==0
    if npts <= 0:
      result=zeros[T](0)
    elif npts==1:
        result = zeros[T](npts)
        result[0] = start
    else:
        result = arange[T](npts)
        let step=(stop-start)/(float(npts)-1.0)

        result *= step
        result += start
        result[npts-1] = stop

proc logspace*[T](start, stop: T, npts: int, base: T = 10): NDArray[T] =
    ## TODO: deal with npts==0
    if npts <= 0:
      result=zeros[T](0)
    elif npts==1:
        result = zeros[T](npts)
        result[0] = start
    else:
        result = arange[T](npts)
        let step=(stop-start)/(float(npts)-1.0)

        result *= step
        result += start
        result[npts-1] = stop

    for i in 0..<npts:
        result[i] = pow(base, result[i])

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

proc reshape*[T](self: NDArray[T], dims: varargs[int]): NDArray[T] =
    ## get an array that shares the underlying data with the
    ## input array, but interprets it with a different shape

    shallowCopy(result, self)

    var newsize=1
    for dim in dims:
        newsize *= dim

    if newsize != self.len:
        let mess="reshape to $1 would change total size to $2 from $3" % [$(@dims),$newsize,$self.len]
        raise newException(ValueError, mess)

    result.dims = @dims
    result.ndim = result.dims.len
    result.strides = calc_strides(result.dims)

    shallowCopy(result.data, self.data)

proc reverse[T](self: seq[T]): seq[T] =
    ## get a new copy of the input sequence, reversed
    newSeq(result, self.len)

    for i in 0..<self.len:
        let irev = (self.len-1) - i

        result[irev] = self[i]

proc transpose*[T](self: NDArray[T]): NDArray[T] =
    ## get an array that shares the underlying data with the
    ## input array, but interprets it with transposed
    ## dimensions

    shallowCopy(result, self)

    result.dims = reverse(self.dims)
    result.strides = reverse(self.strides)
    if self.order == rowMajor:
        result.order=colMajor
    else:
        result.order=rowMajor

#
# reduction over elements
#

proc sum*[T](self: NDArray[T]): T {.inline.} =
    ## sum over elements in the array
    ## TODO: implement summing over specified dimensions/axes
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

proc prod*[T](self: seq[T]): T =
    ## product over elements in the sequence

    result=1
    for i in 0..self.len-1:
        result *= self[i]

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


# TODO: also need to check contiguous for fast one, when
# we implement slices etc.

iterator items*[T](self: NDArray[T]): T {.inline.} =
    ## iterator over all elements of the array.
    ## even if the array is colMajor the order is
    ## last dimension varying the fastest, in which
    ## case the data is not in memory order
    ##
    ## preserving this order makes operatioins between
    ## colMajor and rowMajor straightforward

    for i in indices1d(self):
        yield self.data[i]

iterator mitems*[T](self: var NDArray[T]): var T {.inline.} =
    ## iterator over all elements of the array.
    ## even if the array is colMajor the order is
    ## last dimension varying the fastest, in which
    ## case the data is not in memory order
    ##
    ## preserving this order makes operatioins between
    ## colMajor and rowMajor straightforward

    for i in indices1d(self):
        yield self.data[i]

iterator zip*[S, T](a1: NDArray[S], a2: NDArray[T]): tuple[a: S, b: T] {.inline.} =
    ## iterator to zip two arrays.
    ## this is stride and order aware

    for i1,i2 in izip1d(a1, a2):
        yield (a1.data[i1], a2.data[i2])


#
# getters
#

# specific dimensions for speed; unrolling the loop
# to get the index.

proc `[]`*[T](self: NDArray[T], i: int): T {.inline.} =
    if self.ndim != 1:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 1 index" % $self.ndim)
    self.data[i]

proc `[]`*[T](self: NDArray[T], i, j: int): T {.inline.} =
    if self.ndim != 2:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $self.ndim)
    self.data[
        i*self.strides[0] +
        j
    ]

proc `[]`*[T](self: NDArray[T], i, j, k: int): T {.inline.} =
    if self.ndim != 3:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $self.ndim)
    result=self.data[
        i*self.strides[0] +
        j*self.strides[1] +
        k*self.strides[2]
    ]

proc `[]`*[T](self: NDArray[T], i, j, k, l: int): T {.inline.} =
    if self.ndim != 4:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $self.ndim)

    self.data[
        i*self.strides[0] +
        j*self.strides[1] +
        k*self.strides[2] +
        l*self.strides[3]
    ]

proc `[]`*[T](self: NDArray[T], i, j, k, l, m: int): T {.inline.} =
    # this check is significant, 20% overhead for simple access
    if self.ndim != 5:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $self.ndim)

    self.data[
        i*self.strides[0] +
        j*self.strides[1] +
        k*self.strides[2] +
        l*self.strides[3] +
        m*self.strides[4]
    ]

proc checkIndices[T](self: NDArray[T], indices: varargs[int]) {.inline.} =
    let ndim=self.ndim
    let nind=len(indices)

    if ndim != nind:
        let mess="tried to index $1 dimensional array with $2 indices" % [$ndim, $nind]
        raise newException(IndexError, mess)

proc getIndex1dOld[T](self: NDArray[T], indices: varargs[int]): int {.inline.} =
    checkIndices(self, indices)

    result=0
    for i in 0..self.ndim-1:

        let ind = indices[i]

        # need to make this bounds checking flag aware so we can turn off
        ## checking
        if ind < 0 or ind >= self.dims[i]:
            let mess="index $1 for dimension $1 is out of bounds [0,$3)" % [$ind, $i, $self.dims[i]]
            raise newException(IndexError, mess)

        result += self.strides[i]*ind

proc getIndex1d[T](self: NDArray[T], indices: varargs[int]): int {.inline.} =
    ## this is slower than the predefined ones due to extra lookups
    ## over the indices

    checkIndices(self, indices)

    result=0
    for i in 0..self.ndim-1:
        result += self.strides[i]*indices[i]

proc `[]`*[T](self: NDArray[T], indices: varargs[int]): T {.inline.} =
    ## general element get
    ## with all the calculations and bounds checking this is pretty slow

    let index = getIndex1d(self, indices)
    result = self.data[index]


proc `[]=`*[T,T2](self: var NDArray[T], indices: varargs[int], val: T2) {.inline.} =
    ## general element set
    ##
    ## The value must be convertible to the type of the array

    let index = getIndex1d(self, indices)
    self.data[index] = T(val)

#
#
# scalar array operations
#
# these do not need to be stride aware currently, since we
# only support contiguous arrays
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

# These make new arrays.  when possible, make a copy and
# use the inplace operator

proc `^`*[T,T2](self: NDArray[T], power: T2): NDArray[T] {.inline.} =
    ## get arr^power
    ## todo: check for negative values raised to fractional power
    result = self
    for i in 0..<self.size:
        result.data[i] = pow( float(result[i]), float(power) )

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

    for i in 0..<self.size:
        result.data[i] = val - result.data[i]

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

# in place operations between arrays

template MakeInplaceArithmeticOp(op: expr) =
    proc op*[S, T](self: var NDArray[S], other: NDArray[T]) =
        for i1,i2 in izip1d(self, other):
            op(self.data[i1], self.data[i2])

template MakeInplaceArithmeticOpSpecial(opname: expr, op: expr) =
    ## e.g. for `.=` which, which is a by-element assignment
    ## between two arrays
    proc opname*[S, T](self: var NDArray[S], other: NDArray[T]) =
        for i1,i2 in izip1d(self, other):
            op(self.data[i1], self.data[i2])

MakeInplaceArithmeticOpSpecial(`.=`,`=`)
MakeInplaceArithmeticOp(`+=`)
MakeInplaceArithmeticOp(`-=`)
MakeInplaceArithmeticOp(`*=`)
MakeInplaceArithmeticOp(`/=`)



# operations that make new arrays
#
# currently demand the arrays are of the same type until
# we can implement promotions restrictions
# otherwise, there is no clear way to choose the output type


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

discard """
proc `not` *(self: NDArray[bool]): NDArray[bool] =
    result.init(self.dims)

    for ires, iself in izip1d(result, self):
        result.data[ires] = not self.data[iself]
"""

template MakeBooleanUniOp(op: expr) =
    proc op*(self: NDArray[bool]): NDArray[bool] =
        result.init(self.dims)

        for ires, iself in izip1d(result, self):
            result.data[ires] = op(self.data[iself])


template MakeBooleanOp(op: expr) =
    proc op*(a1: NDArray[bool], a2: NDArray[bool]): NDArray[bool] =
        ensure_compatible_dims(a1, a2)

        result.init(a1.dims)

        for ires, i1, i2 in izip1d(result, a1, a2):
            result.data[ires] = op(a1.data[i1], a2.data[i2])


template MakeCompareOp(op: expr, sop: expr) =
    proc op*[S, T](a1: NDArray[S], a2: NDArray[T]): NDArray[bool] =
        ensure_compatible_dims(a1, a2)

        result.init(a1.dims)

        for ires, i1, i2 in izip1d(result, a1, a2):
            result.data[ires] = sop(a1.data[i1], a2.data[i2])

template MakeCompareOpScalar(op: expr, sop: expr) =
    proc op*[S, T](self: NDArray[S], val: T): NDArray[bool] =
        result.init(self.dims)

        for ires, iself in izip1d(result, self):
            result.data[ires] = sop(self.data[iself], val)

    proc op*[S, T](val: T, self: NDArray[S]): NDArray[bool] =
        result.init(self.dims)

        for ires, iself in izip1d(result, self):
            result.data[ires] = sop(val, self.data[iself])



MakeBooleanUniOp(`not`)

MakeBooleanOp(`and`)
MakeBooleanOp(`or`)
MakeBooleanOp(`xor`)

# because !=, >, and >= are immediate templates in system.nim
# we cannot override them.  So we adopt .!= etc. for *all*
# comparision operators
MakeCompareOp(`.==`,`==`)
MakeCompareOp(`.!=`,`!=`)
MakeCompareOp(`.<`,`<`)
MakeCompareOp(`.<=`,`<=`)
MakeCompareOp(`.>`,`>`)
MakeCompareOp(`.>=`,`>=`)

MakeCompareOpScalar(`.==`,`==`)
MakeCompareOpScalar(`.!=`,`!=`)
MakeCompareOpScalar(`.<`,`<`)
MakeCompareOpScalar(`.<=`,`<=`)
MakeCompareOpScalar(`.>`,`>`)
MakeCompareOpScalar(`.>=`,`>=`)

proc between*[S, T](self: NDArray[S], lo, hi: T): NDArray[bool] =
    result.init(self.dims)

    for ires, iself in izip1d(result, self):
        let val=self.data[iself]
        result.data[ires] = val >= lo and val <= hi

proc alltrue *(self: NDArray[bool]): bool =
    ## returns true if all elements of the input boolean
    ## array are true.
    result=true
    for val in self:
        if val != true:
            result=false
            break

proc anytrue *(self: NDArray[bool]): bool =
    ## returns true if any elements of the input boolean
    ## array are true.
    result=false
    for val in self:
        if val == true:
            result=true
            break

proc any*[T](self: NDArray[T], pred: proc(item: T): bool {.closure.}): bool =
  ## Iterates through an array and checks if some item fulfills the
  ## predicate.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   let a = range[int](10)
  ##   assert any(a, proc (x: int): bool = return x > 8) == true
  ##   assert any(a, proc (x: int): bool = return x > 20) == false

  result=false
  for val in self:
      if pred(val):
          result=true
          break

proc all*[T](self: NDArray[T], pred: proc(item: T): bool {.closure.}): bool =
  ## Iterates through an array and checks if all items fulfill the
  ## predicate.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   let numbers = @[1, 4, 5, 8, 9, 7, 4]
  ##   assert any(numbers, proc (x: int): bool = return x > 8) == true
  ##   assert any(numbers, proc (x: int): bool = return x > 9) == false

  result=true
  for val in self:
      if not pred(val):
          result=false
          break



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

        for ires, iself in izip1d(result, self):
            result.data[ires] = fname(self.data[iself])

    # copying into an existing array
    proc fname*[T](self: NDArray[T], output: var NDArray[T]) {.inline.} =

        ensure_compatible_dims(self, output)

        for iout, iself in izip1d(output, self):
            output.data[iout] = fname(self.data[iself])

# two arguments
template makeUFunc2*(fname: expr) =
    # creating a new array
    proc fname*[T](a1, a2: NDArray[T]): NDArray[T] {.inline.} =
        result.init(a1.dims)

        for ires, i1, i2 in izip1d(result, a1, a2):
            result.data[ires] = fname(a1.data[i1], a2.data[i2])

    # copying into an existing array
    proc fname*[T](a1, a2: NDArray[T], output: var NDArray[T]) {.inline.} =

        ensure_compatible_dims(a1, output)

        for iout, i1, i2 in izip1d(output, a1, a2):
            output.data[iout] = fname(a1.data[i1], a2.data[i2])

proc arctanh(x: float): float {.importc: "atanh", header: "<math.h>".}
proc arctanh(x: float32): float32 {.importc: "atanhf", header: "<math.h>".}
proc arcsinh(x: float): float {.importc: "asinh", header: "<math.h>".}
proc arcsinh(x: float32): float32 {.importc: "asinhf", header: "<math.h>".}
proc arccosh(x: float): float {.importc: "acosh", header: "<math.h>".}
proc arccosh(x: float32): float32 {.importc: "acoshf", header: "<math.h>".}

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

makeUFunc(arcsin)
makeUFunc(arccos)
makeUFunc(arcsinh)
makeUFunc(arccosh)
makeUFunc(arctan)
makeUFunc(arctanh)

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

makeUFunc2(arctan2)
makeUFunc2(hypot)
makeUFunc2(fmod)
makeUFunc2(pow)

#makeUFunc[float](exp)
#proc exp*[T](self: NDArray[T]): NDArray[T] {.inline.} =
#    result.init(self.dims)
#
#    for i in 0..self.size-1:
#        result.data[i] = exp(self.data[i])

proc `$`*[T](self: NDArray[T]): string =
    ## TODO support structured print for dimensions other than 2
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

