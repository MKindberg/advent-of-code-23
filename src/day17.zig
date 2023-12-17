const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Diff = struct {
    x: i64,
    y: i64,
    fn eql(lhs: Diff, rhs: Diff) bool {
        return lhs.x == rhs.x and lhs.y == rhs.y;
    }
    fn toInt(self: Diff) u64 {
        if (self.x == 1) return 0;
        if (self.x == -1) return 1;
        if (self.y == 1) return 2;
        if (self.y == -1) return 3;
        unreachable;
    }
};
const CacheLine = std.ArrayList([16]usize);
const CacheType = std.ArrayList(CacheLine);
const Tile = struct {
    x: usize,
    y: usize,

    fn eql(lhs: Tile, rhs: Tile) bool {
        return lhs.x == rhs.x and lhs.y == rhs.y;
    }
    fn diff(lhs: Tile, rhs: Tile) Diff {
        const lx: isize = @intCast(lhs.x);
        const ly: isize = @intCast(lhs.y);
        const rx: isize = @intCast(rhs.x);
        const ry: isize = @intCast(rhs.y);
        return Diff{ .x = lx - rx, .y = ly - ry };
    }
    fn add(lhs: Tile, rhs: Diff, maxX: usize, maxY: usize) ?Tile {
        const lx: isize = @intCast(lhs.x);
        const ly: isize = @intCast(lhs.y);
        const nx = lx + rhs.x;
        const ny = ly + rhs.y;
        if (nx >= 0 and ny >= 0 and nx < maxX and ny < maxY) return Tile{ .x = @intCast(nx), .y = @intCast(ny) };
        return null;
    }
};

fn printMap(map: []const []const u8, visited: []Tile) void {
    for (0..map.len) |y| {
        for (0..map[0].len) |x| {
            if (contains(visited, Tile{ .x = x, .y = y })) print("#", .{}) else print(".", .{});
        }
        print("\n", .{});
    }
}

fn contains(haystack: []Tile, needle: Tile) bool {
    for (haystack) |tile| {
        if (tile.eql(needle)) {
            return true;
        }
    }
    return false;
}

fn walk(map: []const []const u8, visited: *std.ArrayList(Tile), heat_loss: usize, steps: u8, min_loss: *usize, cache: *CacheType) usize {
    const current = visited.getLast();
    if (visited.items.len > 2) {
        const prev = visited.items[visited.items.len - 2];
        const idx = current.diff(prev).toInt() * 4 + steps;
        const cache_item = cache.items[current.y].items[current.x][idx];
        if (cache_item != 0 and cache_item < heat_loss) {
            return 10000;
        }
        cache.items[current.y].items[current.x][idx] = heat_loss;
    }
    if (current.eql(Tile{ .x = map[0].len - 1, .y = map.len - 1 })) {
        print("heat_loss: {}\n", .{heat_loss});
        // printMap(map, visited.items);
        return heat_loss;
    }

    const diffs: [4]Diff = .{ .{ .x = 1, .y = 0 }, .{ .x = 0, .y = 1 }, .{ .x = -1, .y = 0 }, .{ .x = 0, .y = -1 } };

    for (diffs) |d| {
        if (current.add(d, map[0].len, map.len)) |next| {
            var next_steps =
                if (visited.items.len > 1 and d.eql(current.diff(visited.items[visited.items.len - 2])))
                steps + 1
            else
                0;
            if (next_steps > 2) continue;
            if (!contains(visited.items, next)) {
                const next_heat_loss = heat_loss + map[next.y][next.x] - '0';
                const diff_end = (Tile{ .x = map[0].len - 1, .y = map.len - 1 }).diff(next);
                if (next_heat_loss + @as(usize, @intCast(diff_end.x)) + @as(usize, @intCast(diff_end.y)) < min_loss.*) {
                    visited.append(next) catch unreachable;
                    min_loss.* = @min(min_loss.*, walk(map, visited, next_heat_loss, next_steps, min_loss, cache));
                    _ = visited.pop();
                }
            }
        }
    }
    return min_loss.*;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();
    while (lines.next()) |line| {
        try map.append(line);
    }

    var cache = CacheType.init(allocator);
    defer {
        for (cache.items) |c| c.deinit();
        cache.deinit();
    }
    var row = std.ArrayList([16]usize).init(allocator);
    try row.appendNTimes(std.mem.zeroes([16]usize), map.items[0].len);
    for (map.items) |_| {
        try cache.append(try row.clone());
    }
    row.deinit();

    var visited = std.ArrayList(Tile).init(allocator);
    try visited.append(Tile{ .x = 0, .y = 0 });
    res.p1 = 10000000;
    defer visited.deinit();
    _ = walk(map.items, &visited, 0, 0, &res.p1, &cache);
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
        \\2413432311323
        \\3215453535623
        \\3255245654254
        \\3446585845452
        \\4546657867536
        \\1438598798454
        \\4457876987766
        \\3637877979653
        \\4654967986887
        \\4564679986453
        \\1224686865563
        \\2546548887735
        \\4322674655533
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 102);
}
// 959 too high

// test "test2" {
//     const test_input = "";
//     const res = try solve(std.testing.allocator, test_input);
//     try std.testing.expectEqual(res.p2, 0);
// }
