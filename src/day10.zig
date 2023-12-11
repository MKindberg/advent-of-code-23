const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const MapType = std.ArrayList([]const u8);
const Pos = struct { x: usize, y: usize };

const Dir1 = enum {
    left,
    down,
    right,
    up,
    fn reverse(d: Dir1) Dir1 {
        return switch (d) {
            .left => .right,
            .down => .up,
            .right => .left,
            .up => .down,
        };
    }
};

fn step(map: MapType, prev: Pos, pos: Pos) Pos {
    var p = pos;
    switch (map.items[pos.y][pos.x]) {
        '|' => if (pos.y > prev.y) {
            p.y += 1;
        } else {
            p.y -= 1;
        },
        '-' => if (pos.x > prev.x) {
            p.x += 1;
        } else {
            p.x -= 1;
        },
        'L' => if (pos.x == prev.x) {
            p.x += 1;
        } else {
            p.y -= 1;
        },
        'J' => if (pos.x == prev.x) {
            p.x -= 1;
        } else {
            p.y -= 1;
        },
        '7' => if (pos.x == prev.x) {
            p.x -= 1;
        } else {
            p.y += 1;
        },
        'F' => if (pos.x == prev.x) {
            p.x += 1;
        } else {
            p.y += 1;
        },
        else => unreachable,
    }
    return p;
}

fn getPipe(map: MapType, pos: Pos) u8 {
    return map.items[pos.y][pos.x];
}

fn getStartDir(map: MapType, start: Pos) Pos {
    var p = start;
    p.y -|= 1;
    switch (getPipe(map, p)) {
        '|', 'F', '7' => return p,
        'S' => {},
        else => p.y += 1,
    }
    p.y += 1;
    switch (getPipe(map, p)) {
        '|', 'L', 'J' => return p,
        else => p.y -= 1,
    }
    p.x += 1;
    switch (getPipe(map, p)) {
        '-', 'J', '7' => return p,
        else => p.x -= 1,
    }
    p.x -|= 1;
    switch (getPipe(map, p)) {
        '-', 'L', 'F' => return p,
        'S' => {},
        else => p.y += 1,
    }
    unreachable;
}

fn fillDir(map: MapType, pos: Pos, dir: Dir1, ground: *std.AutoHashMap(Pos, void), pipes: *std.AutoHashMap(Pos, void)) void {
    var p = pos;
    switch (dir) {
        .up => {
            while (p.y > 0) {
                p.y -= 1;
                if (pipes.get(p) == null) ground.put(p, {}) catch unreachable else break;
            }
        },
        .down => {
            while (p.y < map.items.len - 1) {
                p.y += 1;
                if (pipes.get(p) == null) ground.put(p, {}) catch unreachable else break;
            }
        },
        .left => {
            while (p.x > 0) {
                p.x -= 1;
                if (pipes.get(p) == null) ground.put(p, {}) catch unreachable else break;
            }
        },
        .right => {
            while (p.x < map.items[0].len - 1) {
                p.x += 1;
                if (pipes.get(p) == null) ground.put(p, {}) catch unreachable else break;
            }
        },
    }
}

fn fillGround(map: MapType, pos: Pos, dir1: Dir1, side1: *std.AutoHashMap(Pos, void), side2: *std.AutoHashMap(Pos, void), pipes: *std.AutoHashMap(Pos, void)) void {
    fillDir(map, pos, dir1, side1, pipes);
    fillDir(map, pos, dir1.reverse(), side2, pipes);
}

fn nextInDir(pipe: u8, in_dir: Dir1) Dir1 {
    return switch (pipe) {
        '|', '-' => in_dir,
        'L', '7' => switch (in_dir) {
            .down => .left,
            .left => .down,
            .up => .right,
            .right => .up,
        },
        'J', 'F' => switch (in_dir) {
            .down => .right,
            .right => .down,
            .up => .left,
            .left => .up,
        },
        else => in_dir,
    };
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var map = MapType.init(allocator);
    defer map.deinit();
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var i: usize = 0;
    var start = Pos{ .x = 0, .y = 0 };
    while (lines.next()) |line| {
        map.append(line) catch unreachable;
        if (std.mem.indexOfScalar(u8, line, 'S')) |idx| {
            start = Pos{ .x = idx, .y = i };
        }
        i += 1;
    }
    var prev = start;
    var pos = getStartDir(map, start);
    var next: Pos = undefined;

    var in_dir: Dir1 = if (getPipe(map, pos) == '|') .left else .up;
    var side1 = std.AutoHashMap(Pos, void).init(allocator);
    defer side1.deinit();
    var side2 = std.AutoHashMap(Pos, void).init(allocator);
    defer side2.deinit();
    var pipes = std.AutoHashMap(Pos, void).init(allocator);
    defer pipes.deinit();
    pipes.put(start, {}) catch unreachable;
    pipes.put(pos, {}) catch unreachable;

    var count: usize = 1;
    while (true) {
        next = step(map, prev, pos);
        prev = pos;
        pos = next;
        pipes.put(pos, {}) catch unreachable;
        count += 1;
        if (pos.x == start.x and pos.y == start.y) break;
    }
    res.p1 = @divFloor(count, 2);

    fillGround(map, start, in_dir, &side1, &side2, &pipes);
    fillGround(map, pos, in_dir, &side1, &side2, &pipes);
    prev = start;
    pos = getStartDir(map, start);
    while (true) {
        next = step(map, prev, pos);
        prev = pos;
        pos = next;
        count += 1;
        fillGround(map, pos, in_dir, &side1, &side2, &pipes);
        in_dir = nextInDir(getPipe(map, pos), in_dir);
        if (pos.x == start.x and pos.y == start.y) break;
        fillGround(map, pos, in_dir, &side1, &side2, &pipes);
    }
    var inside = if (side1.count() > side2.count()) side2 else side1;
    var outside = if (side1.count() > side2.count()) side1 else side2;
    var it = inside.keyIterator();
    // For some reason the tile under start is added to both lists.
    while (it.next()) |p| {
        if (outside.get(p.*) != null) _ = inside.remove(p.*);
    }
    res.p2 = inside.count();
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

test "test1.1" {
    const test_input =
        \\.....
        \\.S-7.
        \\.|.|.
        \\.L-J.
        \\.....
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 4);
}

test "test1.2" {
    const test_input =
        \\..F7.
        \\.FJ|.
        \\SJ.L7
        \\|F--J
        \\LJ...
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 8);
}

test "test2.1" {
    const test_input =
        \\...........
        \\.S-------7.
        \\.|F-----7|.
        \\.||.....||.
        \\.||.....||.
        \\.|L-7.F-J|.
        \\.|..|.|..|.
        \\.L--J.L--J.
        \\...........
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 4);
}
test "test2.2" {
    const test_input =
        \\.F----7F7F7F7F-7....
        \\.|F--7||||||||FJ....
        \\.||.FJ||||||||L7....
        \\FJL7L7LJLJ||LJ.L-7..
        \\L--J.L7...LJS7F-7L7.
        \\....F-J..F7FJ|L7L7L7
        \\....L7.F7||L7|.L7L7|
        \\.....|FJLJ|FJ|F7|.LJ
        \\....FJL-7.||.||||...
        \\....L---J.LJ.LJLJ...
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 8);
}
test "test2.3" {
    const test_input =
        \\FF7FSF7F7F7F7F7F---7
        \\L|LJ||||||||||||F--J
        \\FL-7LJLJ||||||LJL-77
        \\F--JF--7||LJLJ7F7FJ-
        \\L---JF-JLJ.||-FJLJJ7
        \\|F|F-JF---7F7-L7L|7|
        \\|FFJF7L7F-JF7|JL---7
        \\7-L-JL7||F7|L7F-7F7|
        \\L.L7LFJ|||||FJL7||LJ
        \\L7JLJL-JLJLJL--JLJ.L
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 10);
}
// 472 is too high
