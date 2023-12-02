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

pub fn main() !void {
    const input = @embedFile("input");
    const res = try solve(input);

    std.debug.print("Part 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
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
