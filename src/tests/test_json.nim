import json

proc asIntSeq(node: seq[PJsonNode]): seq[BiggestInt] =
    var output: seq[BiggestInt] = @[]

    for val in node:
        output.add( val.num )

    return output

proc asFloatSeq(node: seq[PJsonNode]): seq[float] =
    var output: seq[float] = @[]

    for val in node:
        output.add( val.fnum )

    return output



let
    small_json = """{"test": 1.3, "key2": true}"""
    jobj = json.parseJson(small_json)

assert (jobj.kind == JObject)
echo($jobj["test"].fnum)
echo($jobj["key2"].bval)

let
    fname="test_json.json"
    jobj_from_file = json.parseFile(fname)

echo("name: '",$jobj_from_file["name"].str,"'")

var nums = jobj_from_file["nums"].elems.asIntSeq()

for el in nums:
    echo("nums:  ",el)

echo("fval: ",jobj_from_file["fval"])


