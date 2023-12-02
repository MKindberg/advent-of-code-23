const std = @import("std");

const Result = struct { p1: usize, p2: usize };

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

pub fn solve(input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        res.p1 += parseLine(1, line);
        res.p2 += parseLine(2, line);
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
    const test_input1 =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    const res = try solve(test_input1);
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
    const res = try solve(test_input2);
    try std.testing.expect(res.p2 == 281);
}
