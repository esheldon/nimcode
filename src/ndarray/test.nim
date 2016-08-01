import ndarray

when isMainModule:

    let nosize = zeros[float](0)
    echo("nosize: ",nosize)

    var s = @[1,2,3]
    let fromseq_copy = ndarray.fromSeq(s)
    let fromseq_shared = ndarray.fromSeq(s, copy=false)


    s[1] = 9999
    echo("from seq copy:   ",fromseq_copy)
    echo("from seq shared: ",fromseq_shared)

    # convert arrays to sequences
    let fixedarr = [3,4,5]
    let fromarr = ndarray.fromSeq( @fixedarr )
    echo("fromarr: ",fromarr)


    var arr = zeros[float](3,4)
    arr[1,2]=3.1

    echo("arr len:  ",arr.len)
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


    var expones = exp(oa)
    echo("\nexp(oa):")
    echo(expones)

    var lnones = expones
    ln(oa, lnones)
    echo("in place ln(oa):")
    echo(lnones)


    echo("setting to 25:")
    oa .= 25
    echo(oa)

    # now try setting elements equal without modifying storage
    var ticopy = zeros[float]( expones.dims )
    ticopy .= expones
    echo("exp copied in place:")
    echo(ticopy)

    var tcopy=zeros[float](3)
    tcopy = expones
    echo("exp copied:")
    echo(tcopy)

    let expones_shared = expones.shareData()
    expones[1,1] = 9999.0
    echo("\nexpones shared:")
    echo(expones_shared)


    # make a copy with these values
    let oacopy = oa

    # set elements all back to 1.0
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

    let tss1 = arange[int](3,6)
    echo("tss1: ",tss1)
    let tss2 = arange[int](3..6)
    echo("tss2: ",tss2)

    var treshape = arange[float](3*3).reshape(3,3)
    echo("range reshaped: ")
    echo(treshape)

    var tdims = @[3,3]
    var tmp=arange[float](prod(tdims)).reshape(tdims)
    tmp *= 3

    tmp += tmp
    echo("\nadding in place:")
    echo(tmp)
    echo(oa)

    var rng = arange[float](3*4).reshape(3,4)
    echo("\nrng:")
    echo(rng)
    echo("rng[1,1]: ",rng[1,1])
    echo("rng[1,2]: ",rng[1,2])

    echo("\nadding one for sums")
    rng += 1
    echo("sum over rng:   ",rng.sum())
    echo("cumsum over rng:  ",rng.cumsum())

    echo("prod over rng:    ",rng.prod())
    echo("cumprod over rng: ",rng.cumprod())




    var arr4 = arange[float](3*4*5*6).reshape(3,4,5,6)
    echo("arr4 strides:",arr4.strides)
    echo("arr4[2,1,3,4]: ",arr4[2,1,3,4])

    var arr5 = arange[float](3*4*5*6*7).reshape(3,4,5,6,7)
    echo("arr5 strides:",arr5.strides)
    echo("arr5[2,1,3,4,2]: ",arr5[2,1,3,4,2])

    let lins = linspace[float](1.0, 2.0, 10)
    echo("lins: ",lins)

    let lins_powerten = lins^2.0
    echo("lins^2:", lins_powerten)

    let logs = logspace[float](0.0, 1.0, 10)
    echo("logs: ",logs)

    # these raise exceptions
    #oa += arr5
    #oa += arr

    let xorig =arange[float](2*3*4).reshape(2,3,4)
    echo("xorig[0,2,1]: ",xorig[0,2,1])

    var xtrans = xorig.transpose()
    echo("xtrans[0,2,1]: ",xtrans[0,2,1])

    echo("iterating xorig:")
    for item in items(xorig):
        echo("    ",item)
    echo("iterating xtrans:")
    for item in items(xtrans):
        echo("    ",item)

    echo("zipping")
    var xsymm1 = arange[float](3*3)
    var xsymm2 = xsymm1.transpose()
    for prs in zip(xsymm1, xsymm2):
        echo(prs)

    for item in mitems(xtrans):
        item = 3
    echo(xtrans)


    #var se: seq[string]

    #setLen(se, 3)

    var ahello = replicate("hello", 3)
    echo("ahello: ",ahello)
    var sarray = strings(3)
    echo("sarray init: ",sarray)
    sarray[1] = "stuff"
    echo("sarray after: ",sarray)

    type
        mData = tuple
            index: int
            x: float
            y: float

    let darr = zeros[mData](3)

    echo("darr zero: ",darr)
