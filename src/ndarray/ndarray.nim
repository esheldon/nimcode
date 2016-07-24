# TODO:  many things, but first
#    - ops creating new arrays
#        - note can use template for reverse of scalar ones, e.g. do the
#          proc for array*x and then template for x*array
#        - +, - (both prefix and infix)
#        - *, /
#    - add slicing
#    - add ordering, e.g. row major vs col major

import sequtils
import strutils

type
    NDArray*[T] = object

        size: Natural          # size is product of all elements of dims
        dims: seq[Natural]     # array holding the size of each dimension
        ndim: Natural

        strides: seq[Natural]  # how many elements are jumped to get 
                               # to the next in each dimension

        data: seq[T]           # use 1-D sequence as backing


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
    result.init(dims)

proc zeros*(dims: varargs[int]): NDArray[float] =
    result.init(dims)

proc zeros*[T](dims: varargs[int]): NDArray[T] =
    result.init(dims)

proc ones*[T](dims: varargs[int]): NDArray[T] =
    result.init(dims)

    for i in 0..<result.size:
        result.data[i] = T(1)

proc arange*[T](dims: varargs[int]): NDArray[T] =
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
# getters
#

# specific dimensions
template `[]`*[T](self: NDArray[T], i: int): auto =
    let ndim=self.ndim

    if ndim != 1:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 1 index" % $ndim)
    self.data[i]

template `[]`*[T](self: NDArray[T], i, j: int): auto =
    let ndim=self.ndim

    if ndim != 2:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $ndim)
    self.data[
        i*self.strides[0] +
        j
    ]

template `[]`*[T](self: NDArray[T], i, j, k: int): auto =
    let ndim=self.ndim

    if ndim != 3:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $ndim)
    self.data[
        i*self.strides[0] +
        j*self.strides[1] +
        k
    ]

template `[]`*[T](self: NDArray[T], i, j, k, l: int): auto =
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

template `[]`*[T](self: NDArray[T], indices: varargs[int]): auto =
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
# array operations
#

# scalars

proc `.=`*[T,T2](self: var NDArray[T], val: T2) {.inline.} =
    ## add a scalar to the array inplace
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

# operations using other arrays
proc `+=`*[T,T2](self: var NDArray[T], other: NDArray[T2]) {.raises: [ValueError].} =

    if other.ndim != self.ndim:
        let mess="mismatched number of dimensions for +=: $1 != $2" % [$self.ndim,$other.ndim]
        raise newException(ValueError, mess)

    for i in 0..self.ndim-1:
        if other.dims[i] != self.dims[i]:
            let mess="mismatched dimensions for +=: $1 != $2" % [$self.dims,$other.dims]
            raise newException(ValueError, mess)

    for i in 0..self.size-1:
        self.data[i] += other.data[i]

proc `-=`*[T,T2](self: var NDArray[T], other: NDArray[T2]) {.raises: [ValueError].} =

    if other.ndim != self.ndim:
        let mess="mismatched number of dimensions for +=: $1 != $2" % [$self.ndim,$other.ndim]
        raise newException(ValueError, mess)

    for i in 0..self.ndim-1:
        if other.dims[i] != self.dims[i]:
            let mess="mismatched dimensions for +=: $1 != $2" % [$self.dims,$other.dims]
            raise newException(ValueError, mess)

    for i in 0..self.size-1:
        self.data[i] -= other.data[i]

proc `*=`*[T,T2](self: var NDArray[T], other: NDArray[T2]) {.raises: [ValueError].} =

    if other.ndim != self.ndim:
        let mess="mismatched number of dimensions for +=: $1 != $2" % [$self.ndim,$other.ndim]
        raise newException(ValueError, mess)

    for i in 0..self.ndim-1:
        if other.dims[i] != self.dims[i]:
            let mess="mismatched dimensions for +=: $1 != $2" % [$self.dims,$other.dims]
            raise newException(ValueError, mess)

    for i in 0..self.size-1:
        self.data[i] *= other.data[i]

proc `/=`*[T,T2](self: var NDArray[T], other: NDArray[T2]) {.raises: [ValueError].} =

    if other.ndim != self.ndim:
        let mess="mismatched number of dimensions for +=: $1 != $2" % [$self.ndim,$other.ndim]
        raise newException(ValueError, mess)

    for i in 0..self.ndim-1:
        if other.dims[i] != self.dims[i]:
            let mess="mismatched dimensions for +=: $1 != $2" % [$self.dims,$other.dims]
            raise newException(ValueError, mess)

    for i in 0..self.size-1:
        self.data[i] /= other.data[i]



#
# accessors
#

proc size*[T](self: NDArray[T]): Natural =
    ## Get a copy of the array size
    result=self.size

proc dims*[T](self: NDArray[T]): seq[Natural] =
    ## Get a copy of the array dimensions
    result=self.dims

proc ndim*[T](self: NDArray[T]): Natural =
    ## Get a copy of the number of dimensions
    result=self.ndim

proc strides*[T](self: NDArray[T]): seq[Natural] =
    ## Get a copy of the strides array
    result=self.strides





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

