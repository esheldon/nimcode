type
    Test* = object
        values: seq[int]

#proc `!=` *(t1, t2: Test): seq[bool] =
#    newSeq(result,2)
#    result[0] = t1.values[0] != t2.values[0]
#    result[1] = t1.values[1] != t2.values[1]

proc `==` *(t1, t2: Test): seq[bool] =
    newSeq(result,2)
    result[0] = t1.values[0] == t2.values[0]
    result[1] = t1.values[1] == t2.values[1]

proc `not`*(self: seq[bool]): seq[bool] =
    newSeq(result,self.len)
    for i in 0..<self.len:
        result[i] = not self[i]


proc makeTest*(data: seq[int]): Test =
    result.values = data
