import ndarray

when isMainModule:

    var arr = zeros[float](3,4)
    arr[1,2]=3.1

    var ii = newSeq[int](1)
    ii[0] = 3
    arr[1,2] = ii[0]

    echo("arr size: ",arr.size)
    echo("arr ndim: ",arr.ndim)
    echo("arr dims: ",arr.dims)
    echo("arr strides: ",arr.strides)
    echo("arr:")
    echo(arr)

    echo("\ntesting array ops")
    arr += 1
    echo(arr)
    arr *= 10
    echo(arr)
    arr /= 10
    echo(arr)
    arr -= 1
    echo(arr)

    var oa=ones[float](3,3)
    echo("\nones:")
    echo(oa)

    let expones = exp(oa)
    echo("exp(oa):")
    echo(expones)

    var lnones = expones
    ln(oa, lnones)
    echo("in place ln(oa):")
    echo(lnones)


    echo("setting to 25:")
    oa .= 25
    echo(oa)


    # make a copy with these values
    let oacopy = oa

    # set back
    oa .= 1
    echo("setting back to 1:")
    echo(oa)

    echo("and the copy:")
    echo(oacopy)

    echo("\nmaking new array, adding 3 second:")
    let adda_second = oa + 3
    echo(adda_second)
    echo("making new array, adding 8 first :")
    let adda_first = 8 + oa
    echo(adda_first)


    echo("\nmaking new array adding a second array")
    let arr_start = ones[float](3,3)
    let arr_sec  = ones[float](3,3)
    let arr_add = arr_start + arr_sec
    echo(arr_add)


    # this shares the underlying data with oa
    echo("\nravelled array:")
    var oaravel = oa.ravel()
    echo(oaravel)


    # verify data is shared
    echo("modifing oa and oaravel")
    oa[1,1]=9999.0
    echo(oa)
    echo(oaravel)
    if oa[1,1] != oaravel[4]:
        raise newException(ValueError,"did not match")

    var tmp=arange[float](3,3)
    tmp *= 3

    oa += tmp
    echo("\nadding in place:")
    echo(tmp)
    echo(oa)

    var rng = arange[float](3,4)
    echo("\nrng:")
    echo(rng)
    echo("rng[1,1]: ",rng[1,1])
    echo("rng[1,2]: ",rng[1,2])


    var arr4 = arange[float](3,4,5,6)
    echo("arr4 strides:",arr4.strides)
    echo("arr4[2,1,3,4]: ",arr4[2,1,3,4])

    var arr5 = arange[float](3,4,5,6,7)
    echo("arr5 strides:",arr5.strides)
    echo("arr5[2,1,3,4,2]: ",arr5[2,1,3,4,2])


    # these raise exceptions
    #oa += arr5
    #oa += arr
