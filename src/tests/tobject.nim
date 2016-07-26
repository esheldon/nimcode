type
    Animal = object of RootObj
        age: int

    Dog = object of Animal

method get_age(self: Animal): int =
    result=self.age

method age_human_years(self: Animal): int =
    result=self.age

method age_human_years(self: Dog): int =
    result=self.age * 7

when isMainModule:

    let cat = Animal(age: 3)
    let dog = Dog(age: 3)

    echo("cat age years:       ", cat.get_age())
    echo("cat age human years: ", cat.age_human_years())

    echo("dog age years:       ", dog.get_age())
    echo("dog age human years: ", dog.age_human_years())
