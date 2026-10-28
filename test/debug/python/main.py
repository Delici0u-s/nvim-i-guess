"""Debugger test program. See test/debug/README.md."""

import sys
from dataclasses import dataclass


@dataclass
class Player:
    name: str
    score: int


def total(players: list[Player]) -> int:
    total_score = 0
    for i, player in enumerate(players):
        total_score += player.score  # BREAK: step here, watch `total_score`, try `i == 2`
    return total_score


def main() -> None:
    players = [Player("ada", 3), Player("bob", 5), Player("cy", 8), Player("dee", 13)]
    print("args:", sys.argv[1:])
    print("total:", total(players))


if __name__ == "__main__":
    main()
