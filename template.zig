const std = @import("std");

const Result = struct { p1: usize, p2: usize };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

pub fn solve(input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        _ = line;
    }
    return res;
}

fn printTimeDiff(from: i128, to: i128) void {
    var diff = to-from;
    if (diff > std.time.ns_per_s) {
        const sec = @divFloor(diff , std.time.ns_per_s);
        std.debug.print("{}s ", .{sec});
        diff -= sec * std.time.ns_per_s;
    }
    if (diff > std.time.ns_per_ms) {
        const ms = @divFloor(diff , std.time.ns_per_ms);
        std.debug.print("{}ms ", .{ms});
        diff -= ms * std.time.ns_per_ms;
    }
    std.debug.print("{}us\n", .{@divFloor(diff,std.time.ns_per_us)});
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

test "test1" {
    const test_input1 = "";
    const res = try solve(test_input1);
    try std.testing.expect(res.p1 == 0);
}

test "test2" {
    const test_input2 = "";
    const res = try solve(test_input2);
    try std.testing.expect(res.p2 == 0);
}
