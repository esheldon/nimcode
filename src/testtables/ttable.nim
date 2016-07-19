import tables
import hashes

type
  Person = object
    firstName, lastName: string

proc hash(x: Person): THash =
  ## Piggyback on the already available string hash proc.
  ##
  ## Without this proc nothing works!
  result = x.firstName.hash !& x.lastName.hash
  result = !$result

var
  salaries = initTable[Person, int]()
  p1, p2: Person

p1.firstName = "Jon"
p1.lastName = "Ross"
salaries[p1] = 30_000

p2.firstName = "소진"
p2.lastName = "박"
salaries[p2] = 45_000
