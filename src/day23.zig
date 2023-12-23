const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };

const Dir = enum {
    Up,
    Down,
    Left,
    Right,
    fn step(self: Dir, pos: Tile) Tile {
        switch (self) {
            .Up => return Tile{ .x = pos.x, .y = pos.y - 1 },
            .Down => return Tile{ .x = pos.x, .y = pos.y + 1 },
            .Left => return Tile{ .x = pos.x - 1, .y = pos.y },
            .Right => return Tile{ .x = pos.x + 1, .y = pos.y },
        }
    }
};
const Tile = struct {
    x: usize,
    y: usize,
    fn in(self: Tile, visited: []Tile) bool {
        for (visited) |v| {
            if (v.x == self.x and v.y == self.y) return true;
        }
        return false;
    }
};

fn filter1(map: []const []const u8, current: Tile, dirs: []const Dir) []const Dir {
    switch (map[current.y][current.x]) {
        '.' => {
            return dirs[0..];
        },
        '>' => {
            const idx: u8 = @intFromEnum(Dir.Right);
            return dirs[idx .. idx + 1];
        },
        '<' => {
            const idx = @intFromEnum(Dir.Left);
            return dirs[idx .. idx + 1];
        },
        '^' => {
            const idx = @intFromEnum(Dir.Up);
            return dirs[idx .. idx + 1];
        },
        'v' => {
            const idx = @intFromEnum(Dir.Down);
            return dirs[idx .. idx + 1];
        },
        else => unreachable,
    }
    unreachable;
}
fn filter2(_: []const []const u8, _: Tile, dirs: []const Dir) []const Dir {
    return dirs[0..];
}

fn hike(map: []const []const u8, comptime filter: fn ([]const []const u8, Tile, []const Dir) []const Dir, visited: *std.ArrayList(Tile), current: Tile) usize {
    if (map[current.y][current.x] == '#') return 0;
    if (current.in(visited.items)) return 0;
    if (current.y == map.len - 1) return visited.items.len;
    visited.append(current) catch unreachable;
    if (current.y == 0) return hike(map, filter, visited, Dir.Down.step(current));

    var max_steps: usize = 0;
    for (filter(map, current, std.enums.values(Dir))) |dir| {
        max_steps = @max(max_steps, hike(map, filter, visited, dir.step(current)));
    }

    _ = visited.pop();
    return max_steps;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();
    while (lines.next()) |line| {
        try map.append(line);
    }
    var visited = std.ArrayList(Tile).init(allocator);
    defer visited.deinit();

    res.p1 = hike(map.items, filter1, &visited, Tile{ .x = 1, .y = 0 });
    visited.clearRetainingCapacity();
    // res.p2 = hike(map.items, filter2, &visited, Tile{ .x = 1, .y = 0 });

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

const test_input =
    \\#.#####################
    \\#.......#########...###
    \\#######.#########.#.###
    \\###.....#.>.>.###.#.###
    \\###v#####.#v#.###.#.###
    \\###.>...#.#.#.....#...#
    \\###v###.#.#.#########.#
    \\###...#.#.#.......#...#
    \\#####.#.#.#######.#.###
    \\#.....#.#.#.......#...#
    \\#.#####.#.#.#########v#
    \\#.#...#...#...###...>.#
    \\#.#.#v#######v###.###v#
    \\#...#.>.#...>.>.#.###.#
    \\#####v#.#.###v#.#.###.#
    \\#.....#...#...#.#.#...#
    \\#.#########.###.#.#.###
    \\#...###...#...#...#.###
    \\###.###.#.###v#####v###
    \\#...#...#.#.>.>.#.>.###
    \\#.###.###.#.###.#.#v###
    \\#.....###...###...#...#
    \\#####################.#
;
test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 94);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 154);
}
