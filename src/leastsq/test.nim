import ndarray
import leastsq

import random
import randarray

type
    MyData = object
        xdata: NDArray[float]
        ydata: NDArray[float]
        ierr: NDArray[float]

proc init(mdata: var MyData, n: int) =

    let pars=[1.0, 2.0]

    mdata.xdata = linspace(-1.0, 1.0, n)
    mdata.ydata = pars[0] + mdata.xdata

    let err = 0.1
    mdata.ierr = zeros[float](n) + 1.0/err

    let rarr = randarray.normal(mean=0.0, sigma=err, size=n)

    mdata.ydata += rarr

proc makeData(n: int): MyData =
    result.init(n)

proc makeDiffer(mdata: MyData): proc =
    ## this closes on mdata
    (
        proc(pars: NDArray[float], fdiff: var NDArray[float]) =
            let model=pars[0] + pars[1]*mdata.xdata

            fdiff .= (model-mdata.ydata)*mdata.ierr
    )

when isMainModule:
    randomize()

    let epsfcn = 1.0e-6

    let npts=10
    let mdata = makeData(npts)

    let differ = makeDiffer(mdata)

    let pars = ndarray.fromSeq( @[1.1, 1.9] )
    var tpars = pars

    var fvec = zeros[float](npts)
    var workarray = zeros[float](npts)
    var fjac = zeros[float]( npts, pars.len )

    differ(pars, fvec)
    echo("fvec:")
    echo(fvec)

    calc_jacobian(differ,
                  pars,
                  fvec, workarray,
                  epsfcn,
                  fjac)
    echo("fjac:")
    echo(fjac)



