import math
import strutils

# object here is implemented as a struct the fields are not accessible outside
# this module, but we can add read-only accessors as procs if we want

type
    Gauss2DPars* = tuple
        p: float
        row: float
        col: float
        irr: float
        irc: float
        icc: float

type
    Gauss2D* = object
        p: float
        row: float
        col: float
        irr: float
        irc: float
        icc: float

        det: float

        drr: float
        drc: float
        dcc: float

        norm: float
        pnorm: float


# can also raise ValueError due to the string interpolation below
proc init*(self: var Gauss2D, p, row, col, irr, irc, icc: float) {.raises: [RangeError,ValueError].} =
    ## initialize a Gauss2D
    self.det = irr*icc - irc*irc
    if self.det <= 0:
        raise newException(RangeError, "found det = $1, <= 0" % $self.det)

    self.p   = p
    self.row = row
    self.col = col
    self.irr = irr
    self.irc = irc
    self.icc = icc

    self.drr = self.irr/self.det
    self.drc = self.irc/self.det
    self.dcc = self.icc/self.det
    self.norm = 1.0/(2*PI*sqrt(self.det))

    self.pnorm = p*self.norm

proc init*(self: var Gauss2D, pars: Gauss2DPars) {.inline.} =
    ## initialize a Gauss2D with the given set of parameters
    ## it seems this is not being inlined by nim
    self.init(pars.p, pars.row, pars.col, pars.irr, pars.irc, pars.icc)

proc show*(self: Gauss2D) =
    echo("  p:   ",self.p)
    echo("  row: ",self.row)
    echo("  col: ",self.col)
    echo("  irr: ",self.irr)
    echo("  irc: ",self.irc)
    echo("  icc: ",self.icc)

proc `$`*(self: Gauss2D): string =
    var tmp = newSeq[string]()

    tmp.add("(p: " & $self.p)
    tmp.add("row: " & $self.row)
    tmp.add("col: " & $self.col)
    tmp.add("irr: " & $self.irr)
    tmp.add("irc: " & $self.irc)
    tmp.add("icc: " & $self.icc & ")")

    result = tmp.join(", ")

when isMainModule:
    var g: Gauss2D

    g.init(1.0, 35.2, 55.6, 4.0, 0.25, 7.6)

    g.show()

    echo g
