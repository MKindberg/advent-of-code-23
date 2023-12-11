const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Point = struct { x: usize, y: usize };

const empty_len = 10;

fn diff(empty_x: [empty_len]usize, x_len: usize, empty_y: [empty_len]usize, y_len: usize, g1: Point, g2: Point, expansion: usize) usize {
    const min_x = @min(g1.x, g2.x);
    const max_x = @max(g1.x, g2.x);
    const min_y = @min(g1.y, g2.y);
    const max_y = @max(g1.y, g2.y);

    var xdiff: usize = max_x - min_x;
    var ydiff: usize = max_y - min_y;

    for (empty_x, 0..) |x, i| {
        if (i > x_len) break;
        if (x > min_x and x < max_x) xdiff += expansion - 1;
    }
    for (empty_y, 0..) |y, i| {
        if (i > y_len) break;
        if (y > min_y and y < max_y) ydiff += expansion - 1;
    }

    return xdiff + ydiff;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();
    var empty_y = std.mem.zeroes([empty_len]usize);
    var y_len: usize = 0;
    var empty_x = std.mem.zeroes([empty_len]usize);
    var x_len: usize = 0;

    {
        var i: usize = 0;
        while (lines.next()) |line| {
            try map.append(line);
            if (std.mem.allEqual(u8, line, '.')) {
                empty_y[y_len] = i;
                y_len += 1;
            }
            i += 1;
        }
        for (0..map.items[0].len) |y| {
            for (map.items) |line| {
                if (line[y] == '#') break;
            } else {
                empty_x[x_len] = y;
                x_len += 1;
            }
        }
    }

    var galaxies = std.ArrayList(Point).init(allocator);
    defer galaxies.deinit();
    for (map.items, 0..) |l, y| {
        for (l, 0..) |t, x| {
            if (t == '#') try galaxies.append(Point{ .x = x, .y = y });
        }
    }

    for (0..galaxies.items.len) |i| {
        for (i + 1..galaxies.items.len) |j| {
            res.p1 += diff(empty_x, x_len, empty_y, y_len, galaxies.items[i], galaxies.items[j], 2);
            res.p2 += diff(empty_x, x_len, empty_y, y_len, galaxies.items[i], galaxies.items[j], 1000000);
        }
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
    \\...#......
    \\.......#..
    \\#.........
    \\..........
    \\......#...
    \\.#........
    \\.........#
    \\..........
    \\.......#..
    \\#...#.....
;
test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 374);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 82000210);
}
