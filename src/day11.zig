const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Point = struct { x: usize, y: usize };

fn diff(g1: Point, g2: Point) usize {
    const min_x = @min(g1.x, g2.x);
    const max_x = @max(g1.x, g2.x);
    const min_y = @min(g1.y, g2.y);
    const max_y = @max(g1.y, g2.y);

    var xdiff: usize = max_x - min_x;
    var ydiff: usize = max_y - min_y;

    return xdiff + ydiff;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();
    var empty_y = std.ArrayList(usize).init(allocator);
    defer empty_y.deinit();
    var empty_x = std.ArrayList(usize).init(allocator);
    defer empty_x.deinit();
    var x_len: usize = 0;

    {
        var i: usize = 0;
        while (lines.next()) |line| {
            try map.append(line);
            if (std.mem.allEqual(u8, line, '.')) {
                try empty_y.append(i);
            }
            i += 1;
        }
        for (0..map.items[0].len) |y| {
            for (map.items) |line| {
                if (line[y] == '#') break;
            } else {
                try empty_x.append(y);
                x_len += 1;
            }
        }
    }

    inline for (.{ "p1", "p2" }, .{ 2, 1000000 }) |part, expansion| {
        var galaxies = std.ArrayList(Point).init(allocator);
        defer galaxies.deinit();
        var yy: usize = 0;
        for (map.items, 0..) |l, y| {
            while (yy < empty_y.items.len and y > empty_y.items[yy]) yy += 1;
            var xx: usize = 0;
            for (l, 0..) |t, x| {
                while (xx < empty_x.items.len and x > empty_x.items[xx]) xx += 1;
                if (t == '#') try galaxies.append(Point{ .x = x + xx * (expansion - 1), .y = y + yy * (expansion - 1) });
            }
        }

        for (0..galaxies.items.len) |i| {
            for (i + 1..galaxies.items.len) |j| {
                @field(res, part) += diff(galaxies.items[i], galaxies.items[j]);
            }
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
