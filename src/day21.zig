const std = @import("std");
const print = std.debug.print;

var max_steps: usize = 64;
const Result = struct { p1: usize, p2: usize };

const CacheItem = struct {
    point: Point,
    steps: usize,
};
const Cache = std.ArrayList(CacheItem);

const Diff = struct { x: isize, y: isize };
const Point = struct {
    x: usize,
    y: usize,
    fn add(self: Point, other: Diff, max_x: usize, max_y: usize) ?Point {
        if (self.x == 0 and other.x < 0) return null;
        if (self.y == 0 and other.y < 0) return null;

        const p = Point{
            .x = @intCast(@as(isize, @intCast(self.x)) + other.x),
            .y = @intCast(@as(isize, @intCast(self.y)) + other.y),
        };
        if (p.x >= max_x or p.y >= max_y) return null;
        return p;
    }
};

fn printMap(map: [][]const u8, visited: []Point) void {
    for (0..map.len) |y| {
        for (0..map[0].len) |x| {
            if ((Point{ .x = x, .y = y }).in(visited)) print("O", .{}) else if (map[y][x] == '#') print("#", .{}) else if (map[y][x] == '.') print(".", .{}) else if (map[y][x] == 'S') print("S", .{}) else unreachable;
        }
        print("\n", .{});
    }
}

fn walk(map: [][]const u8, visited: *Cache, current: Point, steps: usize) void {
    if (steps % 2 == 0) {
        for (visited.items) |*v| {
            if (v.point.x == current.x and v.point.y == current.y) {
                if (steps >= v.steps) return;
                v.steps = steps;
                break;
            }
        } else visited.append(.{ .steps = steps, .point = current }) catch unreachable;
    }
    if (steps >= max_steps) return;
    var diffs: [4]Diff = .{
        Diff{ .x = 0, .y = -1 },
        Diff{ .x = 0, .y = 1 },
        Diff{ .x = -1, .y = 0 },
        Diff{ .x = 1, .y = 0 },
    };
    for (diffs) |d| {
        if (current.add(d, map[0].len, map.len)) |next| {
            if (map[next.y][next.x] == '#') continue;
            walk(map, visited, next, steps + 1);
        }
    }
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();
    var y: usize = 0;
    var start: Point = undefined;
    while (lines.next()) |line| : (y += 1) {
        try map.append(line);
        if (std.mem.indexOf(u8, line, "S")) |x| {
            start = Point{ .x = x, .y = y };
        }
    }

    var visited = Cache.initCapacity(allocator, 1000) catch unreachable;
    defer visited.deinit();
    walk(map.items, &visited, start, 0);
    res.p1 = visited.items.len;
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
        \\...........
        \\.....###.#.
        \\.###.##..#.
        \\..#.#...#..
        \\....#.#....
        \\.##..S####.
        \\.##..#...#.
        \\.......##..
        \\.##.#.####.
        \\.##..##.##.
        \\...........
    ;
    max_steps = 6;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 16);
}

// test "test2" {
//     const test_input = "";
//     const res = try solve(std.testing.allocator, test_input);
//     try std.testing.expectEqual(res.p2, 0);
// }
