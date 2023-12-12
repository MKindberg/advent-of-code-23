const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };

const State = enum { working, broken, unknown };

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

fn isValid(num_broken: []usize, springs: []State) bool {
    var broken_groups = std.mem.tokenizeScalar(State, springs, .working);
    for (num_broken) |n| {
        const group = broken_groups.next() orelse return false;
        if (group.len != n) return false;
    }
    return broken_groups.next() == null;
}

fn search2(num_broken: []usize, spring_groups: [][]const u8, current_group: []const u8) usize {
    if (spring_groups.len == 0 and current_group.len == 0 and num_broken.len == 0) return 1;
    if (num_broken.len == 0) {
        if (std.mem.indexOfScalar(u8, current_group, '#') != null) return 0;
        for (spring_groups) |g| {
            if (std.mem.indexOfScalar(u8, g, '#') != null) return 0;
        }
        return 1;
    }
    if (current_group.len == num_broken[0]) {
        if (spring_groups.len == 0) {
            if (num_broken.len == 1) return 1;
            return 0;
        }
        return search2(num_broken[1..], spring_groups[1..], spring_groups[0]);
    } else if (current_group.len > num_broken[0]) {
        if (current_group[0] == '?') {
            if (current_group.len == num_broken[0] + 1) {
                if (spring_groups.len == 0) {
                    if (num_broken.len == 1) return 1;
                    return 0;
                }
                return search2(num_broken[1..], spring_groups[1..], spring_groups[0]);
            }
            return search2(num_broken[1..], spring_groups, current_group[num_broken[0] + 1 ..]) +
                search2(num_broken, spring_groups, current_group[1..]);
        } else {
            return search2(num_broken[1..], spring_groups, current_group[num_broken[0]..]);
        }
    } else {
        if (std.mem.indexOfScalar(u8, current_group, '#') == null) return search2(num_broken, spring_groups[1..], spring_groups[0]);
        return 0;
    }
}

fn search(num_broken: []usize, springs: []State, max_broken: usize) usize {
    var count: usize = 0;
    if (std.mem.indexOfScalar(State, springs, .unknown)) |i| {
        if (std.mem.count(State, springs, &[_]State{.broken}) > max_broken) {
            return 0;
        }
        if (!(springs[i -| 1] == .working and springs[@min(i + 1, springs.len - 1)] == .working)) {
            springs[i] = .working;
            count += search(num_broken, springs, max_broken);
        }
        springs[i] = .broken;
        count += search(num_broken, springs, max_broken);
        springs[i] = .unknown;
    } else {
        return if (isValid(num_broken, springs)) 1 else 0;
    }
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
        var springs3 = std.ArrayList([]const u8).init(allocator);
        defer springs3.deinit();

        var pp = std.mem.splitScalar(u8, parts.next().?, '.');
        while (pp.next()) |p| {
            springs3.append(p) catch unreachable;
        }
        // const springs = parseSprings(allocator, parts.next().?);
        // defer springs.deinit();
        // const springs2 = duplicateSprings(allocator, springs.items);
        // defer springs2.deinit();
        const num_broken = parseBrokenNum(allocator, parts.next().?);
        defer num_broken.deinit();
        // const num_broken2 = duplicateBrokenNum(allocator, num_broken.items);
        // defer num_broken2.deinit();

        const b = search2(num_broken.items, springs3.items[1..], springs3.items[0]);
        std.debug.print("{}\n", .{b});
        // var max_broken: usize = 0;
        // for (num_broken2.items) |n| max_broken += n;
        // const a = search(num_broken.items, springs.items, max_broken);
        // res.p1 += a;
        // const b = search(num_broken2.items, springs2.items, max_broken);
        // const e = std.math.pow(usize, @divTrunc(b, a), 4);
        // res.p2 += a * e;
        // print("a: {}\n", .{a});
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

test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 21);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 525152);
}

test "test3" {
    const test_input2 = "????.######..#####. 1,6,5";
    const res = try solve(std.testing.allocator, test_input2);
    try std.testing.expectEqual(res.p2, 2500);
}
test "test4" {
    const test_input2 = "?#?#?#?#?#?#?#? 1,3,1,6";
    const res = try solve(std.testing.allocator, test_input2);
    try std.testing.expectEqual(res.p2, 1);
}
