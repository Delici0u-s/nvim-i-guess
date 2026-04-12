def some_method(first, second, third):
    print(first, second, third)


def example_method(condition):
    if condition:
        print("Begin of the work")
        some_method(
            "first string",
            "This is a long string that you can select for refactoring",
            "third string",
        )
        print("End of the work")
    print("The end")
