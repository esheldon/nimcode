import ndarray
import leastsq
import randarray

type
    MyData = object
        xdata: NDArray[float]
        ydata: NDArray[float]
        yierr: NDArray[float]

proc init(mdata: var MyData, n: int) =
    mdata.xdata = linspace(-1.0, 1.0, n)
    mdata.ydata = 1.0 + mdata.xdata^2

    let err = 0.1
    mdata.ierr = zeros(n) + 1.0/err

    let rarr = randarray.normalArray(0.0, err, n)

    mdata.ydata += rarr


proc makeDiffer(mdata: MyData): proc =
    ## this could, for example, compute a function
    (
        proc(pars: NDArray[float], diff: var NDArray[float]) =
            let model=pars[0] + mdata.xdata^pars[1]
            diff .= (model-mdata.data)*mdata.ierr
    )


const x = linspace[float](0.0, PI)

proc fill_sin[T](pars: NDArray[T], fvec: var NDArray[T]) =
    
when isMainModule:
    randomize()

    var
        mdata: MyData

    let npts=10
    mdata.init(npts)
