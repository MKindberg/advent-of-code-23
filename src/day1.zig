const std = @import("std");

const Result = struct { p1: usize, p2: usize };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

const words: [9]struct { []const u8, usize } = .{ .{ "one", 1 }, .{ "two", 2 }, .{ "three", 3 }, .{ "four", 4 }, .{ "five", 5 }, .{ "six", 6 }, .{ "seven", 7 }, .{ "eight", 8 }, .{ "nine", 9 } };

fn getDigit(comptime part: u8, word: []const u8) usize {
    if (std.ascii.isDigit(word[0])) {
        return word[0] - '0';
    }
    if (part == 2) {
        for (words) |w| {
            const l = @min(w[0].len, word.len);
            if (std.mem.eql(u8, w[0], word[0..l])) {
                return w[1];
            }
        }
    }
    return 0;
}

fn parseLine(comptime part: u8, line: []const u8) usize {
    var i: usize = 0;
    const first: usize = while (i < line.len) : (i += 1) {
        const d = getDigit(part, line[i..]);
        if (d != 0) {
            break d;
        }
    } else 0;

    i = 0;
    const last: usize = while (i < line.len) : (i += 1) {
        const d = getDigit(part, line[line.len - 1 - i ..]);
        if (d != 0) {
            break d;
        }
    } else 0;

    return first * 10 + last;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    _ = allocator;
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        res.p1 += parseLine(1, line);
        res.p2 += parseLine(2, line);
    }
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
    const res = try solve(alloc, input);
    std.debug.print("Part 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
}

test "test1" {
    const test_input1 =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    const res = try solve(std.testing.allocator, test_input1);
    try std.testing.expect(res.p1 == 142);
}

test "test2" {
    const test_input2 =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    const res = try solve(std.testing.allocator, test_input2);
    try std.testing.expect(res.p2 == 281);
}
