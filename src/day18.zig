const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Point = struct { x: i32, y: i32 };

fn sortPointsY(_: void, a: Point, b: Point) bool {
    return std.sort.asc(i32)({}, a.y, b.y);
}
fn sortPointsX(_: void, a: Point, b: Point) bool {
    return std.sort.asc(i32)({}, a.x, b.x);
}

fn sameY(p: Point, points: []Point) ?Point {
    for (points) |pp| {
        if (p.y == pp.y) return pp;
    }
    return null;
}
fn sameX(p: Point, points: []Point) ?Point {
    for (points) |pp| {
        if (p.y == pp.y) return pp;
    }
    return null;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var points = std.ArrayList(Point).init(allocator);
    defer points.deinit();
    var current = Point{ .x = 0, .y = 0 };
    try points.append(current);
    while (lines.next()) |line| {
        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const dir = parts.next().?[0];
        const len = std.fmt.parseInt(usize, parts.next().?, 10) catch unreachable;
        const col = parts.next().?;
        _ = col;
        switch (dir) {
            'R' => current.x += @as(i32, @intCast(len)),
            'L' => current.x -= @as(i32, @intCast(len)),
            'U' => current.y += @as(i32, @intCast(len)),
            'D' => current.y -= @as(i32, @intCast(len)),
            else => unreachable,
        }
        try points.append(current);
    }
    std.mem.sortUnstable(Point, points.items, {}, sortPointsY);
    var active = std.ArrayList(Point).init(allocator);
    var y = points.items[0].y;
    _ = y;
    var area:usize = 0;
    _ = area;
    var i:usize = 0;
    while (i < points.items.len) : (i += 1) {
        var p = points.items[i];
        if (sameY(p, active.items) == null) {
            try active.append(p);
            std.mem.sortUnstable(Point, active.items, {}, sortPointsX);
            continue;
        }
        std.mem.sortUnstable(Point, active.items, {}, sortPointsX);
    }
    return res;
}

pub fn getInput() []const u8 {
    return comptime std.mem.trim(u8, @embedFile("inputs/" ++ @typeName(@This())), "\n");
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
    const test_input =
        \\R 6 (#70c710)
        \\D 5 (#0dc571)
        \\L 2 (#5713f0)
        \\D 2 (#d2c081)
        \\R 2 (#59c680)
        \\D 2 (#411b91)
        \\L 5 (#8ceee2)
        \\U 2 (#caa173)
        \\L 1 (#1b58a2)
        \\U 2 (#caa171)
        \\R 2 (#7807d2)
        \\U 3 (#a77fa3)
        \\L 2 (#015232)
        \\U 2 (#7a21e3)
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 62);
}
// 46708 too high

// test "test2" {
//     const test_input = "";
//     const res = try solve(std.testing.allocator, test_input);
//     try std.testing.expectEqual(res.p2, 0);
// }
