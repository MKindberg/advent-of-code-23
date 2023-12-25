const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const StepsDir = struct { dirs: [4]Dir, len: usize };
const CacheItem = struct { tile: Tile, steps: usize, dirs: StepsDir };
const Cache = std.AutoHashMap(Tile, CacheItem);

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
        for (1..visited.len + 1) |i| {
            var idx = visited.len - i;
            if (visited[idx].x == self.x and visited[idx].y == self.y) return true;
        }
        return false;
    }
};

fn filter1(map: []const []const u8, current: Tile, prev_dir: Dir) StepsDir {
    var len: usize = 0;
    var dirs: [4]Dir = undefined;
    var cur = map[current.y][current.x];
    // zig fmt: off
    if((cur == '.' or cur == 'v') and map[current.y + 1][current.x] != '#' and prev_dir != .Up) {dirs[len] = .Down; len += 1;}
    if((cur == '.' or cur == '^') and map[current.y - 1][current.x] != '#' and prev_dir != .Down) {dirs[len] = .Up; len += 1;}
    if((cur == '.' or cur == '<') and map[current.y][current.x - 1] != '#' and prev_dir != .Right) {dirs[len] = .Left; len += 1;}
    if((cur == '.' or cur == '>') and map[current.y][current.x + 1] != '#' and prev_dir != .Left) {dirs[len] = .Right; len += 1;}
    // zig fmt: on
    return StepsDir{ .dirs = dirs, .len = len };
}
fn filter2(map: []const []const u8, current: Tile, prev_dir: Dir) StepsDir {
    var len: usize = 0;
    var dirs: [4]Dir = undefined;
    // zig fmt: off
    if(map[current.y + 1][current.x] != '#' and prev_dir != .Up) {dirs[len] = Dir.Down; len += 1;}
    if(map[current.y - 1][current.x] != '#' and prev_dir != .Down) {dirs[len] = Dir.Up; len += 1;}
    if(map[current.y][current.x - 1] != '#' and prev_dir != .Right) {dirs[len] = Dir.Left; len += 1;}
    if(map[current.y][current.x + 1] != '#' and prev_dir != .Left) {dirs[len] = Dir.Right; len += 1;}
    // zig fmt: on
    return StepsDir{ .dirs = dirs, .len = len };
}

const FilterFn = fn ([]const []const u8, Tile, Dir) StepsDir;

// zig fmt: off
fn hike(
    map: []const []const u8,
    comptime filter: FilterFn,
    cache: *Cache,
    visited: *std.ArrayList(Tile),
    prev_dir: Dir,
    current: Tile,
    steps: usize
) usize {
    // zig fmt: on
    var dirs = filter(map, current, prev_dir);
    var max_steps: usize = 0;
    var next = current;
    var s = steps;
    var p = prev_dir;

    if (cache.get(current)) |item| {
        next = item.tile;
        s += item.steps;
        dirs = item.dirs;
    } else {
        while (dirs.len == 1) : (dirs = filter(map, next, p)) {
            next = dirs.dirs[0].step(next);
            s += 1;
            p = dirs.dirs[0];
            if (next.y == map.len - 1 and next.x == map[0].len - 2) return s;
        }
        cache.put(current, CacheItem{ .tile = next, .steps = s - steps, .dirs = dirs }) catch unreachable;
    }

    if (next.in(visited.items)) return 0;
    visited.append(next) catch unreachable;
    defer _ = visited.pop();

    const c = next;
    for (0..dirs.len) |d| {
        next = dirs.dirs[d].step(c);
        max_steps = @max(max_steps, hike(map, filter, cache, visited, dirs.dirs[d], next, s + 1));
    }
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

    var cache = Cache.init(allocator);
    defer cache.deinit();

    res.p1 = hike(map.items, filter1, &cache, &visited, .Down, Tile{ .x = 1, .y = 1 }, 1);
    // if (map.items.len < 30) {
    visited.clearRetainingCapacity();
    cache.clearRetainingCapacity();
    res.p2 = hike(map.items, filter2, &cache, &visited, .Down, Tile{ .x = 1, .y = 1 }, 1);
    // }

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
    std.debug.assert(res.p1 == 2034);
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
