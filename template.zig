const std = @import("std");

const Result = struct { p1: usize, p2: usize };

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    _ = allocator;
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        _ = line;
    }
    return res;
}

pub fn getInput() []const u8 {
    return @embedFile("inputs/" ++ @typeName(@This()));
}

pub fn readInput(allocator: std.mem.Allocator, path: []const u8) []const u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch @panic("could not open file");
    return file.readToEndAlloc(allocator, file.getEndPos() catch @panic("could not read file")) catch @panic("could not read file");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var args = std.process.args();
    _ = args.skip();
    const input = if (args.next()) |path| readInput(allocator, path) else getInput();
    const res = try solve(allocator, input);
    std.debug.print("\nPart 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
}

test "test1" {
    const test_input1 = "";
    const res = try solve(std.testing.allocator, test_input1);
    try std.testing.expectEqual(res.p1, 0);
}

// test "test2" {
//     const test_input2 = "";
//     const res = try solve(std.testing.allocator, test_input2);
//     try std.testing.expectEqual(res.p2, 0);
// }
