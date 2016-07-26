import ndarray

proc calc_jacobian*(pr: proc,
                    pars, tpars, fvec, workarray: NDArray[float],
                    fjac: var NDArray[float],
                    h: float): int =

    ## pr: the proc to call
    ##    must have signature (pars: NDArray[T], fvec: var NDArray[T])
    ## pars: the set of pars, around which we want the derivative
    ## workpars: a copy of pars
    ## fvec: the proc evaluated at the input parameters
    ## workarray: a work array to store function evaluations
    ## fjac: matrix to fill with jacobian evaluations
    ## epsfcn: derivatives will be calculated with step epsfcn*parval
    ##
    ## TODO:
    ##  - implement args, or require a closure for the proc
    ##  - take max of epsfcn and machine precision

    let eps=epsfcn

    for j in 0..<pars.size:
        let tmp = tpars[j]

        var h=eps*abs(tmp)

        if h==0.0:
            h=eps

        # step ahead
        tpars[j] = tmp + h

        # now fill the workarray with the function evaluation
        pr(tpars, fvec)

        # reset the parameters
        tpars[j] = tmp

