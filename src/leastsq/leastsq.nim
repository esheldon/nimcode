## adapted from minpack

import math
import ndarray

const rdwarf = 3.834e-20
const rgiant = 1.304e19

proc calc_norm_dumb(data: NDArray[float]): float =
    for i in 0..<data.len:
        let tmp=data[i]
        result += tmp*tmp

    result = sqrt(result)

proc calc_norm(data: NDArray[float]): float =
    ## calculate the euclidean norm for the input array
    ## docs from original minpack:
    ##
    ## the euclidean norm is computed by accumulating the sum of
    ## squares in three different sums. the sums of squares for the
    ## small and large components are scaled so that no overflows
    ## occur. non-destructive underflows are permitted. underflows
    ## and overflows do not occur in the computation of the unscaled
    ## sum of squares for the intermediate components.
    ## the definitions of small, intermediate and large components
    ## depend on two constants, rdwarf and rgiant. the main
    ## restrictions on these constants are that rdwarf**2 not
    ## underflow and rgiant**2 not overflow. the constants
    ## given here are suitable for every known computer.

    var s1=0.0
    var s2 = 0.0
    var s3 = 0.0
    var x1max = 0.0
    var x3max = 0.0
    let floatn = float(data.len)
    let agiant = rgiant/floatn
    var tmp = 0.0

    for i in 0..<data.len:
        var xabs = abs(data[i])
        if xabs > rdwarf and xabs < agiant:
            # sum for intermediate sized values
            s2 += xabs*xabs
        elif xabs <= rdwarf:
            # sum for small values

            if xabs <= x3max:
                if xabs != 0.0:
                    tmp = xabs/x3max
                    s3 += tmp*tmp
            else:
                tmp = x3max/xabs
                s3 = 1.0 + s3*tmp*tmp
                x3max = xabs
        else:
            # sum for large values; no zero check required
            if xabs <= x1max:
                tmp = xabs/x1max
                s1 += tmp*tmp
            else:
                tmp = x1max/xabs
                s1 = 1.0 + s1*tmp*tmp
                x1max = xabs

    # now do the final norm calculation
    if s1 == 0.0:
        if s2 == 0.0:
            result = x3max*sqrt(s3)
        elif s2 >= x3max:
            result = sqrt(s2*(1.0+(x3max/s2)*(x3max*s3)))
        elif s2 < x3max:
            result = sqrt(x3max*((s2/x3max)+(x3max*s3)))
    else:
        result = x1max*sqrt(s1+(s2/x1max)/x1max)


const epsmach = 2.22044604926e-16

proc calc_jacobian*(pr: proc,
                    pars: NDArray[float],
                    fvec, workarray: var NDArray[float],
                    epsfcn: float,
                    fjac: var NDArray[float]) =

    ## pr: the proc to call
    ##    must have signature (pars: NDArray[T], fvec: var NDArray[T])
    ## pars: the set of pars, around which we want the derivative
    ## workpars: a copy of pars
    ## fvec: the proc evaluated at the input parameters
    ## workarray: a work array to store function evaluations
    ## fjac: Nfunc x Npars matrix to fill with jacobian evaluations
    ## epsfcn: derivatives will be calculated with step epsfcn*parval
    ##
    ## TODO:
    ##  - implement args, or require a closure for the proc
    ##  - take max of epsfcn and machine precision

    let Npars=pars.len
    let Nfunc=fvec.len
    let eps = sqrt( max(epsfcn, epsmach) )

    var tpars = pars

    for j in 0..<Npars:
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

        for i in 0..<Nfunc:
            fjac[i, j] = (workarray[i] - fvec[i])/h

when isMainModule:
    let data_med   = ndarray.fromSeq( @[1.5, 2.1, 2.2, 0.1] )
    let data_large = ndarray.fromSeq( @[1.5e300, 2.1e300, 2.2e300, 0.1e300] )
    let data_small = ndarray.fromSeq( @[1.5e-300, 2.1e-300, 2.2e-300, 0.1e-300] )

    let norm_med_dumb = calc_norm_dumb(data_med)
    let norm_med_good = calc_norm(data_med)
    let norm_large_dumb = calc_norm_dumb(data_large)
    let norm_large_good = calc_norm(data_large)
    let norm_small_dumb = calc_norm_dumb(data_small)
    let norm_small_good = calc_norm(data_small)


    echo("norm med good: ",norm_med_good)
    echo("norm med dumb: ",norm_med_dumb)
    echo("norm large good: ",norm_large_good)
    echo("norm large dumb: ",norm_large_dumb)
    echo("norm small good: ",norm_small_good)
    echo("norm small dumb: ",norm_small_dumb)
