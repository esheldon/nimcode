# we might want to use the matrix from linalg?
# it has some oddities....
import linalg

when isMainModule:
    let vm1 = randomMatrix(6, 9)
    echo(vm1)

    # this doesn't work
    #var em1 = exp(-vm1)

    #echo(em1)
