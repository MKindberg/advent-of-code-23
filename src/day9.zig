const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: i32, p2: i32 };
const max_nums = 25;
const max_depth = 25;

fn extrapolateLine(line: []const u8) [2]i32 {
    var diffs: [max_depth][max_nums]i32 = undefined;

    var str_nums = std.mem.tokenizeScalar(u8, line, ' ');
    var len: usize = 0;
    while (str_nums.next()) |n| {
        diffs[0][len] = std.fmt.parseInt(i32, n, 10) catch unreachable;
        len += 1;
    }
    var d: usize = 0;

    while (!std.mem.allEqual(i32, diffs[d][0..len], 0)) {
        for (1..len) |i| {
            diffs[d + 1][i - 1] = diffs[d][i] - diffs[d][i - 1];
        }
        len -= 1;
        d += 1;
    }

    var items: [2]i32 = .{ 0, 0 };
    for (0..d + 1) |i| {
        items[0] = diffs[d - i][len - 1] + items[0];
        items[1] = diffs[d - i][0] - items[1];
        len += 1;
    }

    return items;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    _ = allocator;
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const n = extrapolateLine(line);
        res.p1 += n[0];
        res.p2 += n[1];
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

const test_input =
    \\0 3 6 9 12 15
    \\1 3 6 10 15 21
    \\10 13 16 21 30 45
;
test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 114);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 2);
}
