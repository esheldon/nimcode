import topdef

#type
#    Test = object
#        values: seq[int]


#proc `!=`(t1, t2: Test): seq[bool] =
#    newSeq(result,2)
#    result[0] = t1.values[0] != t2.values[0]
#    result[1] = t1.values[1] != t2.values[1]


#proc makeTest*(data: seq[int]): Test =
#    result.values = data

let t1 = makeTest(@[1,2])
let t2 = makeTest(@[1,2])

let comp = (t1 != t2)
#let comp = not (t1 == t2)
echo(comp)
