const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const max_width = 120;
const max_height = 120;
const EnergizedType = [4][max_height]std.bit_set.StaticBitSet(max_width);

const Direction = enum { Up, Down, Left, Right };
const Laser = struct { x: usize, y: usize, dir: Direction };

fn step(map: [][]const u8, cur: Laser) ?Laser {
    var c = cur;
    switch (cur.dir) {
        .Up => if (cur.y == 0) return null else {
            c.y -= 1;
        },
        .Left => if (cur.x == 0) return null else {
            c.x -= 1;
        },
        .Down => if (cur.y == map.len - 1) return null else {
            c.y += 1;
        },
        .Right => if (cur.x == map[0].len - 1) return null else {
            c.x += 1;
        },
    }
    return c;
}

fn walk(map: [][]const u8, energized: *EnergizedType, cur: Laser) void {
    if ((energized[@intFromEnum(cur.dir)][cur.y].isSet(cur.x))) return;
    energized[@intFromEnum(cur.dir)][cur.y].set(cur.x);

    var c = cur;
    while (map[c.y][c.x] == '.') {
        c = step(map, c) orelse return;
        energized[@intFromEnum(c.dir)][c.y].set(c.x);
    }
    switch (map[c.y][c.x]) {
        '.' => {},
        '/' => switch (cur.dir) {
            .Up => c.dir = .Right,
            .Left => c.dir = .Down,
            .Down => c.dir = .Left,
            .Right => c.dir = .Up,
        },
        '\\' => switch (cur.dir) {
            .Up => c.dir = .Left,
            .Left => c.dir = .Up,
            .Down => c.dir = .Right,
            .Right => c.dir = .Down,
        },
        '-' => switch (cur.dir) {
            .Left, .Right => {},
            .Up, .Down => {
                c.dir = .Left;
                if (step(map, c)) |n| walk(map, energized, n);
                c.dir = .Right;
            },
        },
        '|' => switch (cur.dir) {
            .Up, .Down => {},
            .Left, .Right => {
                c.dir = .Up;
                if (step(map, c)) |n| walk(map, energized, n);
                c.dir = .Down;
            },
        },
        else => unreachable,
    }
    c = step(map, c) orelse return;
    walk(map, energized, c);
}

fn numEnergized(energized: *EnergizedType) usize {
    var sum: usize = 0;
    for (0..energized[0].len) |i| {
        energized[0][i].setUnion(energized[1][i]);
        energized[0][i].setUnion(energized[2][i]);
        energized[0][i].setUnion(energized[3][i]);
        sum += energized[0][i].count();
    }
    return sum;
}

fn clear(energized: *EnergizedType) void {
    for (energized) |*d| {
        for (d) |*r| r.setRangeValue(.{ .start = 0, .end = max_width }, false);
    }
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var energized = std.mem.zeroes(EnergizedType);
    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();
    while (lines.next()) |line| {
        try map.append(line);
    }

    var start: Laser = .{ .x = 0, .y = 0, .dir = .Right };
    walk(map.items, &energized, start);
    res.p1 = numEnergized(&energized);

    const use_threads = true;
    if (use_threads) {
        var results = std.mem.zeroes([3]usize);
        var threads: [3]std.Thread = undefined;
        threads[0] = try std.Thread.spawn(.{}, upStart, .{ map.items, &results[0] });
        threads[1] = try std.Thread.spawn(.{}, downStart, .{ map.items, &results[1] });
        threads[2] = try std.Thread.spawn(.{}, leftStart, .{ map.items, &results[2] });
        rightStart(map.items, &res.p2);
        for (threads) |thread| thread.join();
        for (results) |r| res.p2 = @max(res.p2, r);
    } else {
        upStart(map.items, &res.p2);
        downStart(map.items, &res.p2);
        leftStart(map.items, &res.p2);
        rightStart(map.items, &res.p2);
    }
    return res;
}

fn rightStart(map: [][]const u8, res: *usize) void {
    var energized = std.mem.zeroes(EnergizedType);
    for (0..map.len) |y| {
        var start: Laser = .{ .x = 0, .y = y, .dir = .Right };
        clear(&energized);
        walk(map, &energized, start);
        res.* = @max(res.*, numEnergized(&energized));
    }
}

fn leftStart(map: [][]const u8, res: *usize) void {
    var energized = std.mem.zeroes(EnergizedType);
    for (0..map.len) |y| {
        var start: Laser = .{ .x = map[0].len - 1, .y = y, .dir = .Left };
        clear(&energized);
        walk(map, &energized, start);
        res.* = @max(res.*, numEnergized(&energized));
    }
}

fn downStart(map: [][]const u8, res: *usize) void {
    var energized = std.mem.zeroes(EnergizedType);
    for (0..map[0].len) |x| {
        var start: Laser = .{ .x = x, .y = 0, .dir = .Down };
        clear(&energized);
        walk(map, &energized, start);
        res.* = @max(res.*, numEnergized(&energized));
    }
}

fn upStart(map: [][]const u8, res: *usize) void {
    var energized = std.mem.zeroes(EnergizedType);
    for (0..map[0].len) |x| {
        var start: Laser = .{ .x = x, .y = map.len - 1, .dir = .Up };
        clear(&energized);
        walk(map, &energized, start);
        res.* = @max(res.*, numEnergized(&energized));
    }
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

const test_input =
    \\.|...\....
    \\|.-.\.....
    \\.....|-...
    \\........|.
    \\..........
    \\.........\
    \\..../.\\..
    \\.-.-/..|..
    \\.|....-|.\
    \\..//.|....
;
test "test1" {
    print("test1\n", .{});
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 46);
}

test "test2" {
    print("test2\n", .{});
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 51);
}
