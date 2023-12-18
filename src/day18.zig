const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Point = struct { x: isize, y: isize };
const HoleType = std.AutoHashMap(Point, void);
const Edges = struct { minX: isize, minY: isize, maxX: isize, maxY: isize };

fn dig(hole: *HoleType, current: *Point, dir: u8, len: usize) void {
    var c = current;
    for (0..len) |_| {
        switch (dir) {
            'U' => c.y += 1,
            'D' => c.y -= 1,
            'L' => c.x -= 1,
            'R' => c.x += 1,
            else => unreachable,
        }
        hole.put(c.*, {}) catch unreachable;
    }
}

fn inside(hole: *HoleType, edges: Edges, p: Point) bool {
    var y = p.y;
    while (y >= edges.minY) : (y -= 1) {
        if (hole.get(Point{ .x = p.x, .y = y }) != null) break;
    } else return false;

    y = p.y;
    while (y <= edges.maxY) : (y += 1) {
        if (hole.get(Point{ .x = p.x, .y = y }) != null) break;
    } else return false;

    var x = p.x;
    while (x >= edges.minX) : (x -= 1) {
        if (hole.get(Point{ .x = x, .y = p.y }) != null) break;
    } else return false;
    x = p.x;
    while (x <= edges.maxX) : (x += 1) {
        if (hole.get(Point{ .x = x, .y = p.y }) != null) break;
    } else return false;

    return true;
}

fn fill(hole: *HoleType, edges: Edges) void {
    var y = edges.minY;
    while (y <= edges.maxY) : (y += 1) {
        var x = edges.minX;
        while (x <= edges.maxX) : (x += 1) {
            if (hole.get(Point{ .x = x, .y = y }) != null) continue;
            if (inside(hole, edges, Point{ .x = x, .y = y }))
                hole.put(Point{ .x = x, .y = y }, {}) catch unreachable;
        }
    }
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var hole = HoleType.init(allocator);
    defer hole.deinit();
    var current = Point{ .x = 0, .y = 0 };
    try hole.put(current, {});
    var e = Edges{ .minX = 0, .minY = 0, .maxX = 0, .maxY = 0 };
    while (lines.next()) |line| {
        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const dir = parts.next().?[0];
        const len = std.fmt.parseInt(usize, parts.next().?, 10) catch unreachable;
        const col = parts.next().?;
        _ = col;
        dig(&hole, &current, dir, len);
        e.minX = @min(e.minX, current.x);
        e.minY = @min(e.minY, current.y);
        e.maxX = @max(e.maxX, current.x);
        e.maxY = @max(e.maxY, current.y);
    }
    fill(&hole, e);
    res.p1 = hole.count();
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
