import math
import strutils

proc atanh(x: float): float {.importc: "atanh", header: "<math.h>".}

type
    Shape* = tuple
        g1: float
        g2: float
        e1: float
        e2: float

proc `$`*(self: Shape): string =
    ## make representation of this object
    var tmp = newSeq[string]()

    tmp.add("(g1: " & $self.g1)
    tmp.add( "g2: " & $self.g2 & ")")

    result = tmp.join(", ")

proc shear_reduced(g1, g2, s1, s2: float): auto =
    ## shear using the reduced shear formula
    let A = 1 + g1*s1 + g2*s2
    let B = g2*s1 - g1*s2
    let denom_inv = 1.0/(A*A + B*B)

    var g1o = A*(g1 + s1) + B*(g2 + s2)
    var g2o = A*(g2 + s2) - B*(g1 + s1)

    g1o *= denom_inv
    g2o *= denom_inv

    (g1o,g2o)

proc set_g*(self: var Shape, g1, g2: float) {.raises: [RangeError,ValueError].} =
    ## set the shape using g style
    self.g1=g1
    self.g2=g2

    let g=sqrt(g1*g1 + g2*g2)

    if g==0:
        self.e1=0
        self.e2=0
    else:

        if g >= 1.0:
            raise newException(RangeError, "g value $1 out of range (-1,1)" % $g)

        let eta = 2*atanh(g)
        var e = tanh(eta)
        if e >= 1.0:
            # round off?
            e = 0.99999999

        let fac = e/g

        self.e1 = fac*g1
        self.e2 = fac*g2

proc set_e*(self: var Shape, e1, e2: float) {.raises: [RangeError,ValueError].} =
    ## set the shape using e style
    self.e1=e1
    self.e2=e2

    let e=sqrt(e1*e1 + e2*e2)

    if e==0:
        self.g1=0
        self.g2=0
    else:

        if e >= 1.0:
            raise newException(RangeError, "e value $1 out of range (-1,1)" % $e)

        let eta = atanh(e)
        var g = tanh(0.5*eta)
        if g >= 1.0:
            # round off?
            g = 0.99999999

        let fac = g/e

        self.g1 = fac*e1
        self.g2 = fac*e2

proc shear*(self, s: Shape): Shape =
    ## shear the Shape, returning a new Shape
    let (g1o,g2o) = shear_reduced(self.g1, self.g2, s.g1, s.g2)
    result.set_g(g1o,g2o)

proc shear_inplace*(self: var Shape, s: Shape) =
    ## shear the Shape in place
    let (g1o,g2o) = shear_reduced(self.g1, self.g2, s.g1, s.g2)
    self.set_g(g1o,g2o)


when isMainModule:
    var shape1: Shape
    var shape2: Shape

    echo("\nsetting g")
    shape1.set_g(0.2, 0.3)
    echo("shape: ",shape1)

    echo("\nsetting e")
    shape2.set_e(0.3539823008849557, 0.5309734513274336)
    echo("shape: ",shape2)

    let shape3 = shape1.shear(shape2)
    echo("shape after shear: ",shape3)

    shape1.shear_inplace(shape2)
    echo("shape after shear: ",shape3)
