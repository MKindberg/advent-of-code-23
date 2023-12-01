const std = @import("std");

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
    } else unreachable;

    i = 0;
    const last: usize = while (i < line.len) : (i += 1) {
        const d = getDigit(part, line[line.len - 1 - i ..]);
        if (d != 0) {
            break d;
        }
    } else unreachable;

    return first * 10 + last;
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var sum1: usize = 0;
    var sum2: usize = 0;
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        sum1 += parseLine(1, line);
        sum2 += parseLine(2, line);
    }
    std.debug.print("Part 1: {}\n", .{sum1});
    std.debug.print("Part 2: {}\n", .{sum2});
}

test "test1" {
    const input =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    var sum: usize = 0;

    var it = std.mem.tokenizeScalar(u8, input[0..], '\n');
    while (it.next()) |l| {
        sum += parseLine(1, l);
    }
    try std.testing.expect(sum == 142);
}

test "test2" {
    const input =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    var sum: usize = 0;

    var it = std.mem.tokenizeScalar(u8, input[0..], '\n');
    while (it.next()) |l| {
        sum += parseLine(2, l);
    }
    try std.testing.expect(sum == 281);
}
