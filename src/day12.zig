const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };

const State = enum { working, broken, unknown };
const Key = struct { spring_len: usize, broken_len: usize, cur: State };
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

fn parseBrokenNum(res: *std.ArrayList(usize), broken: []const u8) void {
    var nums = std.mem.splitScalar(u8, broken, ',');
    while (nums.next()) |n| {
        res.append(std.fmt.parseInt(usize, n, 10) catch unreachable) catch unreachable;
    }
}

fn parseSprings(res: *std.ArrayList(State), springs: []const u8) void {
    for (springs) |s| {
        res.append(switch (s) {
            '.' => .working,
            '#' => .broken,
            '?' => .unknown,
            else => unreachable,
        }) catch unreachable;
    }
}

fn hashBrokenNum(num_broken: []usize) u128 {
    var hash: u128 = 0;
    for (num_broken) |n| {
        hash *= 10;
        hash += n;
    }
    return hash;
}

fn search(num_broken: []usize, springs: []State, cache: *Cache) usize {
    if (num_broken.len == 0) {
        if (std.mem.indexOfScalar(State, springs, .broken) == null) return 1;
        return 0;
    }
    if (std.mem.allEqual(State, springs, .working)) return 0;
    if (springs.len == 0) {
        return 0;
    }
    const key = Key{ .spring_len = springs.len, .broken_len = num_broken.len, .cur = springs[0] };
    if (cache.get(key)) |v| return v;
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
        count += search(num_broken[1..], springs[i + num_broken[0] + 1 ..], cache);
    } else {
        springs[i] = .working;
        count += search(num_broken, springs[i..], cache);
        springs[i] = .broken;
        count += search(num_broken, springs[i..], cache);
        springs[i] = .unknown;
    }
    cache.put(key, count) catch unreachable;
    return count;
}

fn duplicateSprings(res: *std.ArrayList(State), springs: []State) void {
    for (0..5) |_| {
        res.appendSlice(springs) catch unreachable;
        res.append(.unknown) catch unreachable;
    }
    _ = res.swapRemove(res.items.len - 1);
}

fn duplicateBrokenNum(res: *std.ArrayList(usize), num_broken: []usize) void {
    for (0..5) |_| {
        res.appendSlice(num_broken) catch unreachable;
    }
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var springs = std.ArrayList(State).initCapacity(allocator, 50) catch unreachable;
    defer springs.deinit();
    var extended_springs = std.ArrayList(State).initCapacity(allocator, 50) catch unreachable;
    defer extended_springs.deinit();
    var num_broken = std.ArrayList(usize).initCapacity(allocator, 50) catch unreachable;
    defer num_broken.deinit();
    var num_broken2 = std.ArrayList(usize).initCapacity(allocator, 50) catch unreachable;
    defer num_broken2.deinit();
    var cache = Cache.init(allocator);
    defer cache.deinit();

    while (lines.next()) |line| {
        var parts = std.mem.splitScalar(u8, line, ' ');
        parseSprings(&springs, parts.next().?);
        duplicateSprings(&extended_springs, springs.items);
        parseBrokenNum(&num_broken, parts.next().?);
        duplicateBrokenNum(&num_broken2, num_broken.items);

        res.p1 += search(num_broken.items, springs.items, &cache);
        cache.clearRetainingCapacity();
        res.p2 += search(num_broken2.items, extended_springs.items, &cache);

        cache.clearRetainingCapacity();
        springs.clearRetainingCapacity();
        extended_springs.clearRetainingCapacity();
        num_broken.clearRetainingCapacity();
        num_broken2.clearRetainingCapacity();
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

// test "test1.lines" {
//     for (0..6) |i| {
//         std.debug.print("inp: {s}\n", .{test_inputs[i]});
//         const res = try solve(std.testing.allocator, test_inputs[i]);
//         try std.testing.expectEqual(res.p1, test_results[i]);
//     }
// }
//
// test "test1" {
//     const res = try solve(std.testing.allocator, test_input);
//     try std.testing.expectEqual(res.p1, 21);
// }

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 525152);
}
