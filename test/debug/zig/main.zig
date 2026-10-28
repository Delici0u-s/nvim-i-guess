// Debugger test program. See test/debug/README.md.
const std = @import("std");

const Player = struct {
    name: []const u8,
    score: i32,
};

fn total(players: []const Player) i32 {
    var sum: i32 = 0;
    for (players, 0..) |player, i| {
        _ = i;
        sum += player.score; // BREAK: step here, watch `sum`, try `i == 2`
    }
    return sum;
}

pub fn main() void {
    const players = [_]Player{
        .{ .name = "ada", .score = 3 },
        .{ .name = "bob", .score = 5 },
        .{ .name = "cy", .score = 8 },
        .{ .name = "dee", .score = 13 },
    };
    std.debug.print("total: {d}\n", .{total(&players)});
}
