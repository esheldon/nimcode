## todo: versions where we have our own random state
import ndarray
import random
import math

proc uniform*(): float {.inline.} =
    ## get a random number in the range [0,1)
    result = random(float(high(int32)))/float(high(int32))

proc uniform*(lo, hi: float): float {.inline.} =
    ## get a random number in the range [lo,hi)
    result = lo + (hi-lo)*uniform()

proc uniformArray*(lo, hi: float, size: int): NDArray[float] =
    ## get an array of random numbers in the range [lo,hi)
    result.init(size)

    for i in 0..<result.len:
        result[i] = uniform(lo, hi)

proc normal*(): float =
    ## get random number drawn from a Gaussian with mean zero and
    ## standard deviation 1
    var
        x1, x2, w: float
        # y2
 
    while true:
        # x1,x2 in the range [-1,1)
        x1 = 2.0*random(1.0) - 1.0
        x2 = 2.0*random(1.0) - 1.0
        w = x1*x1 + x2*x2

        if w < 1.0:
            break

    w = sqrt( (-2.0*ln( w ) ) / w )
    result = x1*w
    #y2 = x2*w;

proc normal*(mn, sigma: float): float =
    ## get random number drawn from a Gaussian with mean mn and
    ## standard deviation sigma
    result = mn + sigma*normal()

proc normalArray*(mn, sigma: float, size: int): NDArray[float] =
    ## get an array of random numbers drawn from a Gaussian with mean mn and
    ## standard deviation sigma

    result.init(size)
    
    for i in 0..<result.len:
        result[i] = normal(mn, sigma)

when isMainModule:
    randomize()

    var r1 = uniform()
    echo("r: ",r1)
    r1 = uniform(-1.0, 1.0)
    echo("r: ",r1)

    let ua = uniformArray(-1.0, 1.0, 10)
    echo("ua: ",ua)

    let rn1 = normal()
    echo("rn: ",rn1)

    let rna1 = normalArray(10.0, 2.0, 8)
    echo("rna: ",rna1)
