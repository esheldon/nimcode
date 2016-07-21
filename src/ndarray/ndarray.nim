# TODO:  many things, but first
#    - add ordering, e.g. row major vs col major
import strutils

type
    NDArray*[T] = object
        dims: seq[int]
        ndim:int

        data: seq[T]
        size: int


proc newArray*[T](self: var NDArray[T], dims: varargs[int]) =
    ## return a new array
    let ndim = len(dims)

    newSeq(self.dims, ndim)
    self.ndim=ndim

    var size=1
    for i in 0..ndim-1:
        self.dims[i] = dims[i]
        size = size * dims[i]

    newSeq(self.data, size)
    self.size=size

proc newArray*[T](dims: varargs[int]): NDArray[T] =
    newArray(result, dims)


proc ones*[T](dims: varargs[int]): NDArray[T] =
    newArray[T](result,dims)
    result.data=T(1)

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
    self.data[i*self.dims[1] + j]

template `[]`*[T](self: NDArray[T], i, j, k: int): auto =
    let ndim=self.ndim

    if ndim != 3:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $ndim)
    self.data[
        i*self.dims[2]*self.dims[1] +
        j*self.dims[2]              +
        k
    ]

template `[]`*[T](self: NDArray[T], i, j, k, l: int): auto =
    let ndim=self.ndim

    if ndim != 4:
        raise newException(IndexError,
                           "tried to index $1 dimensional array with 2 indices" % $ndim)
    self.data[
        i*self.dims[3]*self.dims[2]self.dims[1] +
        j*self.dims[3]*self.dims[2]             +
        k*self.dims[3]                          +
        l
    ]

proc `$`*[T](self: NDArray[T]): string =

    #[
    if self.ndim==2:
        var lines = newSeq[string]()

        stdout.write("[")

        for i in 0..self.dims[0]-1:
            var line: string

            if i==0:
                line.add("[[")
            else:
                line.add(" [")

            for j in 0..self.dims[1]-1:

                line.add( $self[i,j] )

                if j < self.dims[1]-1:
                    line.add(", ")

            if i < self.dims[0]-1:
                line.add("]")
            else:
                line.add("]]")

            lines.add(line)

            result = lines.join("\n")
    else:
        result = $self.data
    ]#
    result = $self.data


# general version
#template `[]`*(self: NDArray[T], indices: varargs[int]): auto =
#
#    var index=0
#    for i in indices:
#        index = index + self.strides[i]*indices[i]
#
#    self.data[i * m.N + j]

when isMainModule:

    var arr = newArray[float](3,4)

    echo("arr:")
    echo(arr)
    #[

    var rng = range[float](3,4)
    echo("rng:")
    echo(rng)
    echo("rng[1,1]: ",rng[1,1])

    echo("rng[1]: ",rng[1])
    ]#
