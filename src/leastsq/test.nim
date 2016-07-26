import ndarray
import leastsq

type
    MyData = object
        xdata: NDArray[float]
        ydata: NDArray[float]
        yierr: NDArray[float]

proc init(mdata: var MyData, n: int) =
    mdata.xdata = linspace(-1.0, 1.0, n)
    mdata.ydata = 1.0 + mdata.xdata^2

    let err = sqrt(mdata.ydata)
    mdata.ierr = 1.0/err


proc makeDiffer(mdata: MyData): proc =
    (
        proc(data: NDArray[float], diff: var NDArray[float]) =
            diff = data
            diff -= mdata.data
            diff /= mdata.ierr
    )


const x = linspace[float](0.0, PI)

proc fill_sin[T](pars: NDArray[T], fvec: var NDArray[T]) =
    
when isMainModule:


