# Scratch file: safe to edit or delete, nothing imports it.
"""Small scratch file for trying out editor features (LSP, formatting, diagnostics)."""

from dataclasses import dataclass


@dataclass
class Point:
    x: float
    y: float

    def distance_to(self, other: "Point") -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5


def fizzbuzz(n: int) -> list[str]:
    out = []
    for i in range(1, n + 1):
        word = ("Fizz" if i % 3 == 0 else "") + ("Buzz" if i % 5 == 0 else "")
        out.append(word or str(i))
    return out


if __name__ == "__main__":
    print(Point(0, 0).distance_to(Point(3, 4)))
    print(", ".join(fizzbuzz(15)))
