const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };

const State = enum { working, broken, unknown };
const Key = struct { pos: usize, num: u128 };
const Cache = std.AutoHashMap(Key, usize);

fn printSprings(springs: []State) void {
    for (springs) |s| {
        switch (s) {
            .working => std.debug.print(".", .{}),
            .broken => std.debug.print("#", .{}),
            .unknown => std.debug.print("?", .{}),
        }
    }
    std.debug.print("\n", .{});
}

fn parseBrokenNum(allocator: std.mem.Allocator, broken: []const u8) std.ArrayList(usize) {
    var res = std.ArrayList(usize).init(allocator);
    var nums = std.mem.splitScalar(u8, broken, ',');
    while (nums.next()) |n| {
        res.append(std.fmt.parseInt(usize, n, 10) catch unreachable) catch unreachable;
    }
    return res;
}

fn parseSprings(allocator: std.mem.Allocator, springs: []const u8) std.ArrayList(State) {
    var res = std.ArrayList(State).init(allocator);
    for (springs) |s| {
        res.append(switch (s) {
            '.' => .working,
            '#' => .broken,
            '?' => .unknown,
            else => unreachable,
        }) catch unreachable;
    }
    return res;
}

fn hashBrokenNum(num_broken: []usize) u128 {
    var hash: u128 = 0;
    for (num_broken) |n| {
        hash *= 10;
        hash += n;
    }
    return hash;
}

fn search(num_broken: []usize, springs: []State, cache: *Cache, pos: usize) usize {
    // const key = Key{ .pos = pos, .num = hashBrokenNum(num_broken) };
    // if (cache.get(key)) |v| return v;
    if (num_broken.len == 0) {
        if (std.mem.indexOfScalar(State, springs, .broken) == null) return 1;
        return 0;
    }
    if (std.mem.allEqual(State, springs, .working)) return 0;
    if (springs.len == 0) {
        return 0;
    }
    var count: usize = 0;
    var i: usize = 0;
    while (i < springs.len and springs[i] == .working) i += 1;
    if (i == springs.len) return 0;
    if (springs[i] == .broken) {
        if (i + num_broken[0] > springs.len) return 0;
        if (std.mem.indexOfScalar(State, springs[i .. i + num_broken[0]], .working) != null) return 0;
        if (i + num_broken[0] == springs.len) {
            if (num_broken.len == 1) return 1;
            return 0;
        }
        if (springs[i + num_broken[0]] == .broken) return 0;
        count += search(num_broken[1..], springs[i + num_broken[0] + 1 ..], cache, pos + i + num_broken[0] + 1);
    } else {
        springs[i] = .working;
        count += search(num_broken, springs[i..], cache, i);
        springs[i] = .broken;
        count += search(num_broken, springs[i..], cache, i);
        springs[i] = .unknown;
    }
    // cache.put(key, count) catch unreachable;
    return count;
}

fn duplicateSprings(allocator: std.mem.Allocator, springs: []State) std.ArrayList(State) {
    var res = std.ArrayList(State).init(allocator);
    for (0..2) |_| {
        res.appendSlice(springs) catch unreachable;
        res.append(.unknown) catch unreachable;
    }
    return res;
}

fn duplicateBrokenNum(allocator: std.mem.Allocator, num_broken: []usize) std.ArrayList(usize) {
    var res = std.ArrayList(usize).init(allocator);
    for (0..2) |_| {
        res.appendSlice(num_broken) catch unreachable;
    }
    return res;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var parts = std.mem.splitScalar(u8, line, ' ');
        const springs = parseSprings(allocator, parts.next().?);
        defer springs.deinit();
        const springs2 = duplicateSprings(allocator, springs.items);
        defer springs2.deinit();
        const num_broken = parseBrokenNum(allocator, parts.next().?);
        defer num_broken.deinit();
        const num_broken2 = duplicateBrokenNum(allocator, num_broken.items);
        defer num_broken2.deinit();

        var cache = Cache.init(allocator);
        defer cache.deinit();
        const a = search(num_broken.items, springs.items, &cache, 0);
        res.p1 += a;
        const b = search(num_broken2.items, springs2.items, &cache, 0);
        res.p2 += b;
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
    \\???.### 1,1,3
    \\.??..??...?##. 1,1,3
    \\?#?#?#?#?#?#?#? 1,3,1,6
    \\????.#...#... 4,1,1
    \\????.######..#####. 1,6,5
    \\?###???????? 3,2,1
;

const test_inputs = [_][]const u8{
    "???.### 1,1,3",
    ".??..??...?##. 1,1,3",
    "?#?#?#?#?#?#?#? 1,3,1,6",
    "????.#...#... 4,1,1",
    "????.######..#####. 1,6,5",
    "?###???????? 3,2,1",
};
const test_results = [_]usize{ 1, 4, 1, 1, 4, 10 };

test "test1.lines" {
    for (0..6) |i| {
        std.debug.print("inp: {s}\n", .{test_inputs[i]});
        const res = try solve(std.testing.allocator, test_inputs[i]);
        try std.testing.expectEqual(res.p1, test_results[i]);
    }
}

test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 21);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 525152);
}
