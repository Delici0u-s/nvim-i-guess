// Debugger test program. See test/debug/README.md.
#include <stdio.h>

typedef struct {
	const char *name;
	int score;
} Player;

static int total(const Player *players, int count) {
	int sum = 0;
	for (int i = 0; i < count; i++) {
		sum += players[i].score; // BREAK: step here, watch `sum`, try `i == 2`
	}
	return sum;
}

int main(int argc, char **argv) {
	Player players[] = {{"ada", 3}, {"bob", 5}, {"cy", 8}, {"dee", 13}};
	int count = sizeof players / sizeof players[0];
	printf("args: %d\n", argc - 1);
	for (int i = 1; i < argc; i++) {
		printf("  %s\n", argv[i]);
	}
	printf("total: %d\n", total(players, count));
	return 0;
}
