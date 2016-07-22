# TODO:  many things, but first
#    - add ordering, e.g. row major vs col major

import sequtils
import strutils

type
    NDArray*[T] = object
        dims: seq[int]
        ndim:int

        strides: seq[int]

        data: seq[T]
        size: int


proc newArray*[T](self: var NDArray[T], dims: varargs[int]) =
    ## return a new array
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
    newArray(result, dims)


proc ones*[T](dims: varargs[int]): NDArray[T] =
    newArray[T](result,dims)

    for i in 0..<result.size:
        result.data[i] = T(1)

proc range*[T](dims: varargs[int]): NDArray[T] =
    newArray[T](result, dims)

    for i in 0..result.size-1:
        result.data[i] = T(i)


# we can generalize these with strides later
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


proc `$`*[T](self: NDArray[T]): string =

    if self.ndim==2:
        var lines = newSeq[string]()

        for i in 0..self.dims[0]-1:
            var line = newSeq[string]()


            for j in 0..self.dims[1]-1:
                line.add( $self[i,j] )

            var tmp = line.join(", ")

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


when isMainModule:

    var arr = newArray[float](3,4)

    echo("arr:")
    echo(arr)

    var oa=ones[float](3,3)
    echo("ones:")
    echo(oa)

    var rng = range[float](3,4)
    echo("rng:")
    echo(rng)
    echo("rng[1,1]: ",rng[1,1])
    echo("rng[1,2]: ",rng[1,2])

    var arr4 = range[float](3,4,5,6)
    echo("arr4 strides:",arr4.strides)
    echo("arr4[2,1,3,4]: ",arr4[2,1,3,4])

    var arr5 = range[float](3,4,5,6,7)
    echo("arr5 strides:",arr5.strides)
    echo("arr5[2,1,3,4,2]: ",arr5[2,1,3,4,2])


