const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Tile = enum { Empty, Round, Cube };
const Direction = enum { North, West, South, East };
const MapType = std.ArrayList(std.ArrayList(Tile));

fn printMap(map: MapType) void {
    for (map.items) |m| {
        for (m.items) |t| {
            switch (t) {
                .Cube => print("#", .{}),
                .Round => print("O", .{}),
                .Empty => print(".", .{}),
            }
        }
        print("\n", .{});
    }
    print("\n", .{});
}

const north_multiple = 1000_000;
fn calcWeights(map: MapType) usize {
    var totalNorth: usize = 0;
    var totalWest: usize = 0;
    for (0..map.items.len) |y| {
        for (0..map.items[0].items.len) |x| {
            if (map.items[y].items[x] == .Round) {
                totalNorth += map.items.len - y;
                totalWest += map.items[0].items.len - x;
            }
        }
    }
    return totalNorth * north_multiple + totalWest;
}

fn roll(map: MapType, dir: Direction) void {
    switch (dir) {
        .North => {
            for (0..map.items[0].items.len) |x| {
                var pos: usize = 0;
                for (0..map.items.len) |y| {
                    switch (map.items[y].items[x]) {
                        .Cube => pos = y + 1,
                        .Round => {
                            std.mem.swap(Tile, &map.items[y].items[x], &map.items[pos].items[x]);
                            pos += 1;
                        },
                        .Empty => {},
                    }
                }
            }
        },
        .West => {
            for (0..map.items.len) |y| {
                var pos: usize = 0;
                for (0..map.items[0].items.len) |x| {
                    switch (map.items[y].items[x]) {
                        .Cube => pos = x + 1,
                        .Round => {
                            std.mem.swap(Tile, &map.items[y].items[x], &map.items[y].items[pos]);
                            pos += 1;
                        },
                        .Empty => {},
                    }
                }
            }
        },
        .South => {
            for (0..map.items[0].items.len) |x| {
                var pos: usize = map.items.len - 1;
                for (0..map.items.len) |yy| {
                    var y = map.items.len - yy - 1;
                    switch (map.items[y].items[x]) {
                        .Cube => pos = y -| 1,
                        .Round => {
                            std.mem.swap(Tile, &map.items[y].items[x], &map.items[pos].items[x]);
                            pos -|= 1;
                        },
                        .Empty => {},
                    }
                }
            }
        },
        .East => {
            for (0..map.items.len) |y| {
                var pos: usize = map.items[0].items.len - 1;
                for (0..map.items[0].items.len) |xx| {
                    var x = map.items[0].items.len - xx - 1;
                    switch (map.items[y].items[x]) {
                        .Cube => pos = x -| 1,
                        .Round => {
                            std.mem.swap(Tile, &map.items[y].items[x], &map.items[y].items[pos]);
                            pos -|= 1;
                        },
                        .Empty => {},
                    }
                }
            }
        },
    }
}

fn cycle(map: MapType) void {
    for (std.enums.values(Direction)) |dir| {
        roll(map, dir);
    }
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var map = MapType.init(allocator);
    defer {
        for (map.items) |m| m.deinit();
        map.deinit();
    }
    while (lines.next()) |line| {
        var m = std.ArrayList(Tile).init(allocator);
        for (line) |c| {
            try switch (c) {
                '#' => m.append(Tile.Cube),
                'O' => m.append(Tile.Round),
                '.' => m.append(Tile.Empty),
                else => unreachable,
            };
        }
        try map.append(m);
    }
    roll(map, Direction.North);
    res.p1 = @divTrunc(calcWeights(map), north_multiple);
    var weights = std.ArrayList(usize).initCapacity(allocator, 500) catch unreachable;
    defer weights.deinit();

    var weight: usize = calcWeights(map);
    while (std.mem.indexOfScalar(usize, weights.items, weight) == null) {
        weights.append(weight) catch unreachable;
        cycle(map);
        weight = calcWeights(map);
    }
    const cycle_start = std.mem.indexOfScalar(usize, weights.items, weight).?;
    const cycle_len = weights.items.len - cycle_start;
    const idx = @mod(1000000000 - cycle_start, cycle_len) + cycle_start;
    res.p2 = @divTrunc(weights.items[idx], north_multiple);

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
    \\O....#....
    \\O.OO#....#
    \\.....##...
    \\OO.#O....O
    \\.O.....O#.
    \\O.#..O.#.#
    \\..O..#O..O
    \\.......O..
    \\#....###..
    \\#OO..#....
;
test "test1" {
    print("\n", .{});
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 136);
}

test "test2" {
    print("\n", .{});
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 64);
}
