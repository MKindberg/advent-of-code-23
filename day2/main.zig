const std = @import("std");

const Result = struct { p1: usize, p2: usize };
const Colors = struct { red: usize, green: usize, blue: usize };

fn parseLine(line: []const u8) Colors {
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    _ = it.next(); //game
    _ = it.next(); //game_num
    var col = Colors{ .red = 0, .green = 0, .blue = 0 };

    while (it.next()) |num| {
        const n = std.fmt.parseInt(usize, num, 10) catch unreachable;
        const c = it.next().?;
        switch (c[0]) {
            'r' => col.red = @max(col.red, n),
            'g' => col.green = @max(col.green, n),
            'b' => col.blue = @max(col.blue, n),
            else => unreachable,
        }
    }
    return col;
}

pub fn solve(input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var game_num: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        game_num += 1;
        const col = parseLine(line);
        if (col.red <= 12 and col.green <= 13 and col.blue <= 14) {
            res.p1 += game_num;
        }
        const score: usize = col.red * col.green * col.blue;
        res.p2 += score;
    }
    return res;
}

fn printTimeDiff(from: i128, to: i128) void {
    var diff = to - from;
    if (diff > std.time.ns_per_s) {
        const sec = @divFloor(diff, std.time.ns_per_s);
        std.debug.print("{}s ", .{sec});
        diff -= sec * std.time.ns_per_s;
    }
    if (diff > std.time.ns_per_ms) {
        const ms = @divFloor(diff, std.time.ns_per_ms);
        std.debug.print("{}ms ", .{ms});
        diff -= ms * std.time.ns_per_ms;
    }
    std.debug.print("{}us\n", .{@divFloor(diff, std.time.ns_per_us)});
}

pub fn main() !void {
    const input = @embedFile("input");

    const start = std.time.nanoTimestamp();
    const res = try solve(input);
    const stop = std.time.nanoTimestamp();

    std.debug.print("Part 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
    printTimeDiff(start, stop);
}

test "test" {}
