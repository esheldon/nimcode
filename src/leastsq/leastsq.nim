import ndarray

proc calc_jacobian(pr: proc,
                   pars, fvec, workarray: NDArray[float],
                   fjac: var NDArray[float],
                   h: float): int =

    ## pr: the proc to call
    ## pars: the set of pars, around which we want the derivative
    ## fvec: the proc evaluated at the input parameters
    ## workarray: a work array to store function evaluations
    ## fjac: matrix to fill with jacobian evaluations
    ## epsfcn: derivatives will be calculated with step epsfcn*parval
    ##
    ## TODO:
    ##  - implement args, or figure out how to do encapsulation for the proc.
    ##    I think it is not possible in nim
    ##  - take max of epsfcn and machine precision

    let eps=epsfcn

    # get a copy of the parameters
    var tpars=pars

    for j in 0..<pars.size:
        let tmp = tpars[j]

        var h=eps*abs(tmp)

        if h==0.0:
            h=eps

        # step ahead
        tpars[j] = tmp + h

        # now fill the workarray with the function evaluation
        pr(tpars

        # reset the parameters
        tpars[j] = tmp
