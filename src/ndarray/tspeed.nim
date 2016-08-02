import ndarray


let dims = [100,100,10,10,10]
let arr1 = ones[float](10_000_000).reshape(dims)
let arr2 = 1.0 + ones[float](10_000_000).reshape(dims)

var start = 0.0

# using general getter twice as slow
for i1 in 0..<dims[0]:
    for i2 in 0..<dims[1]:
        for i3 in 0..<dims[2]:
            for i4 in 0..<dims[3]:
                for i5 in 0..<dims[4]:
                    start += arr1[i1,i2,i3,i4,i5]*arr2[i1,i2,i3,i4,i5]

# about 20% faster than with special 5-element
# getter; but about the same if extra ndim check is turned off

#for val1, val2 in zip(arr1, arr2):
#    start += val1*val2

echo("val: ",start)

