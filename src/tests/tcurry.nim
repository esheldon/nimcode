import ndarray

type
    MyData = object
        name: string
        data: NDArray[float]
        ierr: NDArray[float]

proc init(mdata: var MyData, n: int) =
    mdata.name="test name"
    mdata.data = arange[float](n)
    mdata.data += 1

    mdata.ierr = replicate(10.0, n)


# versions that make a new array
#proc makeDiffer(mdata: MyData): auto = (proc(data: NDArray[float]): NDarray[float] = data-mdata.data)
#proc makeDiffer(mdata: MyData): auto = 
#    (proc(data: NDArray[float]): NDarray[float] =
#        data-mdata.data)

# two different ways
#proc makeDiffer(mdata: MyData): auto =
#    (
#        proc(data: NDArray[float], diff: var NDArray[float]) =
#            diff = data
#            diff -= mdata.data
#            diff /= mdata.ierr
#    )
proc makeDiffer(mdata: MyData): proc =
    return proc(data: NDArray[float], diff: var NDArray[float]) =
            diff = data
            diff -= mdata.data
            diff /= mdata.ierr


when isMainModule:
    let n=10
        
    var mdata: MyData

    # [0,1,...n-1]
    mdata.init(n)

    # same but with 5 added
    var data = arange[float](n) + 5

    let differ = makeDiffer(mdata)

    #let diff=differ(data)

    var diff = zeros[float](n)

    differ(data, diff)

    echo("diff:")
    echo(diff)
