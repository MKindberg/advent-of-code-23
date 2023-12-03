const std = @import("std");

const Result = struct { p1: usize, p2: usize };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

/// Parse the number containing the index x and move x to the last index in the number
fn parseNum(line: []const u8, x: *usize) usize {
    if (std.ascii.isDigit(line[x.*])) {
        var start: isize = @intCast(x.*);
        while (start >= 0 and std.ascii.isDigit(line[@intCast(start)])) : (start -= 1) {}
        var end = x.*;
        while (end < line.len and std.ascii.isDigit(line[end])) : (end += 1) {}
        x.* = end - 1;
        return std.fmt.parseInt(usize, line[@intCast(start + 1)..end], 10) catch @panic("could not parse number");
    }
    return 0;
}

fn inMatrix(matrix: std.ArrayList([]const u8), x: usize, y: usize) bool {
    return y < matrix.items.len and x < matrix.items[y].len;
}

fn isGear(matrix: std.ArrayList([]const u8), x: usize, y: usize) bool {
    return matrix.items[y][x] != '.' and !std.ascii.isDigit(matrix.items[y][x]);
}

/// Find all numbers and check if they're adjacent to a gear
fn part1(matrix: std.ArrayList([]const u8)) usize {
    var sum: usize = 0;
    for (matrix.items, 0..) |line, y| {
        var x: usize = 0;
        while (x < line.len) : (x += 1) {
            if (std.ascii.isDigit(line[x])) {
                const x0 = x;
                var x1 = x;
                while (x1 < line.len and std.ascii.isDigit(line[x1])) : (x1 += 1) {}
                outer: for ((y -| 1)..y + 2) |yy| {
                    for (x0 -| 1..x1 + 1) |xx| {
                        if (inMatrix(matrix, xx, yy) and isGear(matrix, xx, yy)) {
                            sum += std.fmt.parseInt(usize, line[x0..x1], 10) catch @panic("could not parse number");
                            break :outer;
                        }
                    }
                }
                x = x1;
            }
        }
    }
    return sum;
}

/// Find all gears and check if they have exactly two adjacent numbers
fn part2(matrix: std.ArrayList([]const u8)) usize {
    var sum: usize = 0;
    for (matrix.items, 0..) |line, y| {
        var x: usize = 0;
        while (x < line.len) : (x += 1) {
            if (isGear(matrix, x, y)) {
                var prod: usize = 1;
                var num: usize = 0;
                outer: for ((y -| 1)..y + 2) |yy| {
                    var xx: usize = x -| 1;
                    while (xx < x + 2) : (xx += 1) {
                        if (inMatrix(matrix, xx, yy) and std.ascii.isDigit(matrix.items[yy][xx])) {
                            prod *= parseNum(matrix.items[yy], &xx);
                            num += 1;
                            if (num > 2) break :outer;
                        }
                    }
                }
                if (num == 2) sum += prod;
            }
        }
    }
    return sum;
}

pub fn solve(input: []const u8) !Result {
    var buf: [22500]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const fba_allocator = fba.allocator();

    var res = Result{ .p1 = 0, .p2 = 0 };

    var matrix = std.ArrayList([]const u8).init(fba_allocator);
    defer matrix.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        matrix.append(line) catch @panic("could not append line");
    }

    res.p1 = part1(matrix);
    res.p2 = part2(matrix);

    return res;
}

pub fn getInput() []const u8 {
    return @embedFile("inputs/" ++ @typeName(@This()));
}

pub fn readInput(path: []const u8) []const u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch @panic("could not open file");
    return file.readToEndAlloc(alloc, file.getEndPos() catch @panic("could not read file")) catch @panic("could not read file");
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();
    const input = if (args.next()) |path| readInput(path) else getInput();
    const res = try solve(input);
    std.debug.print("\nPart 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
}

test "test_parse_num" {
    const input = "467..114..";
    var x: usize = 0;
    try std.testing.expect(parseNum(input, &x) == 467);
    try std.testing.expect(x == 2);
}

test "test1" {
    const test_input1 =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    const res = try solve(test_input1);
    try std.testing.expect(res.p1 == 4361);
}

test "test2" {
    const test_input2 =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\.......755
        \\...$..*...
        \\.664.598..
    ;
    const res = try solve(test_input2);
    try std.testing.expect(res.p2 == 467835);
}

test "real" {
    const res = try solve(getInput());
    try std.testing.expect(res.p1 == 540131);
    try std.testing.expect(res.p2 == 86879020);
}
