# since nimrod has built-in arrays, we don't actually need a gmix type
# can just use seq

import tables
import hashes
import gauss2d
import shape
import strutils
import random

type
    GMix* = seq[Gauss2D]

proc `$`*(self: GMix): string =
    var tmp = newSeq[string]()

    for i in 0..self.len-1:
        if i != 0:
            tmp.add(" " & $self[i])
        else:
            tmp.add($self[i])
    result = "[" & tmp.join(",\n") & "]"


# pure means we must do qualified, GMixModel.full
type
  GMixModel* {.pure.} = enum
      full,
      coellip,
      turb,
      gauss,
      exp,
      dev

type
  GMixSimpleModel* {.pure.} = enum
      turb,
      gauss,
      exp,
      dev


proc hash(model: GMixModel): Hash =
    let mint = int(model)
    result = mint.hash
    result = !$result

type
    GMixSimplePars* = tuple
        model: GmixSimpleModel
        data: seq[float]
        shape: Shape


let nGaussTable = {GMixModel.exp:6,
                   GMixModel.dev:10,
                   GMixModel.turb:3}.to_table

proc newGMixSimplePars*(model: GMixSimpleModel,
                        par_seq: seq[float]): GMixSimplePars =
    if par_seq.len != 6:
        raise newException(ValueError,
            "simple pars must have 6 elements, got $1" % $len(par_seq))

    result.model=model

    # this makes a copy
    result.data = par_seq

    result.shape.set_g(par_seq[2], par_seq[3])

proc newGMix*(num: int) : GMix =
    newSeq(result, num)

#proc newGMixModel(pars: GMixPars) GMix =
#    case pars.model:
#        of GMixModel.full:
#            echo "full"
#        of GMixModel.coellip:
#            echo "coellip"
#        of GMixModel.turb:
#            echo "turb"
#        of GMixModel.exp:
#            echo "exp"
#        of GMixModel.dev:
#            echo "dev"

const
    pvals_exp = @[
        0.00061601229677880041,
        0.0079461395724623237,
        0.053280454055540001,
        0.21797364640726541,
        0.45496740582554868,
        0.26521634184240478,
    ]

    fvals_exp = @[
      0.002467115141477932,
      0.018147435573256168,
      0.07944063151366336,
      0.27137669897479122,
      0.79782256866993773,
      2.1623306025075739,
    ]

    pvals_dev = @[
      6.5288960012625658e-05,
      0.00044199216814302695,
      0.0020859587871659754,
      0.0075913681418996841,
      0.02260266219257237,
      0.056532254390212859,
      0.11939049233042602,
      0.20969545753234975,
      0.29254151133139222,
      0.28905301416582552,
    ]

    fvals_dev = @[
      3.068330909892871e-07,
      3.551788624668698e-06,
      2.542810833482682e-05,
      0.0001466508940804874,
      0.0007457199853069548,
      0.003544702600428794,
      0.01648881157673708,
      0.07893194619504579,
      0.4203787615506401,
      3.055782252301236,
    ]

    pvals_turb = @[
      0.596510042804182,
      0.4034898268889178,
      1.303069003078001e-07,
    ]

    fvals_turb = @[
      0.5793612389470884,
      1.621860687127999,
      7.019347162356363,
    ]

    pvals_gauss = @[1.0]
    fvals_gauss = @[1.0]



proc fillGMixSimple(self: var GMix,
                    pars: GMixSimplePars,
                    fvals: seq[float],
                    pvals: seq[float]) =
    if len(fvals) != 6:
        raise newException(ValueError,
                           "fvals must be length 6, got $1" % $len(pvals))
    if len(pvals) != 6:
        raise newException(ValueError,
                           "pvals must be length 6, got $1" % $len(pvals))

    let row = pars.data[0]
    let col = pars.data[1]
    let T   = pars.data[4]
    let F   = pars.data[5]

    let e1 = pars.shape.e1
    let e2 = pars.shape.e2

    for i in 0..self.len-1:
        let T_i_2 = 0.5*T*fvals[i]
        let F_i   = F*pvals[i]

        # no copy made
        self[i].init(F_i,
                     row,
                     col,
                     T_i_2*(1.0-e1),
                     T_i_2*e2,
                     T_i_2*(1.0+e1))

proc newGMixSimple(pars: GMixSimplePars) : GMix =
  ## make a new simple model gaussian mixture
  result=newGMix(6)
  case pars.model:
    of GMixSimpleModel.gauss:
        fillGMixSimple(result, pars, fvals_gauss, pvals_gauss)

    of GMixSimpleModel.exp:
        fillGMixSimple(result, pars, fvals_exp, pvals_exp)

    of GMixSimpleModel.dev:
        fillGMixSimple(result, pars, fvals_dev, pvals_dev)

    of GMixSimpleModel.turb:
        fillGMixSimple(result, pars, fvals_turb, pvals_turb)

#proc newGMixCoellip(pars: GMixPars, num: int) : GMix =
#    newSeq(result, num) 

iterator mitems(self: var GMix): var Gauss2D =
    ##
    var i = 0
    while i < self.len:
        yield self[i]
        inc i

when isMainModule:

    var gm = newGMix(3)

    # no copy made here (see nimcache)
    for i in 0..gm.len-1:
        let fi=float(i)
        gm[i].init(
            p=1.0+fi,
            row=15.0+fi,
            col=16.0+fi,
            irr=4.5,
            irc=0.2,
            icc=6.7,
        )

    echo("gm:\n",gm)

    # this makes a copy into local variable g each time through
    # (see nimcache)
    echo("gm again:")
    for g in gm:
        echo(g)

    # mitems iterates, returning modifiable items; under the hood g is a
    # pointer to the Gauss2D
    echo("modifying in loop:")
    for g in mitems(gm):

        # This time show hout to use a Gauss2DPars note only a single stack
        # allocated structure is reused each time

        let pars: Gauss2DPars = (
            p:   random(1.0..2.0),
            row: 15.0 + random(-1.0..1.0),
            col: 16.0 + random(-1.0..1.0),
            irr: 2.0*(1.0 + 0.1*random(-1.0..1.0)),
            irc: random(-0.1..0.1),
            icc: 3.0*(1.0 + 0.1*random(-1.0..1.0)),
        )

        g.init(pars)

    echo("gm:\n",gm)

    echo("ngauss for exp is: ",nGaussTable[GMixModel.exp])

    # float literals need number after decimal
    var pdata = @[15.0, 16.0, 0.2, 0.3, 16.0, 100.0]

    echo("pdata orig: ",pdata)

    var pexp = newGMixSimplePars(GMixSimpleModel.exp, pdata)
    var gmexp = newGMixSimple(pexp)

    echo("gmexp:")
    echo(gmexp)
