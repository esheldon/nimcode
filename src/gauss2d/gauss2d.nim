import math
import strutils

# tuple here is implemented as a struct, a value type
type
    Gauss2D* = tuple
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


proc init*(self: var Gauss2D, p, row, col, irr, irc, icc: float) {.raises: [RangeError].} =

    self.det = irr*icc - irc*irc
    if self.det <= 0:
        raise newException(RangeError, "found det <= 0")

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
