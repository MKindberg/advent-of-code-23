const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };

const MapType = [32 * 32 * 32][2]u16;

fn hash(pos: []const u8) u16 {
    return @as(u16, pos[0] - 'A') * 32 * 32 + @as(u16, pos[1] - 'A') * 32 + @as(u16, pos[2] - 'A');
}

fn walk(map: MapType, directions: []u8, start: []const u8) usize {
    var steps: usize = 0;
    var current = hash(start);
    const end = 'Z' - 'A';
    while (true) {
        for (directions, 1..) |dir, s| {
            current = map[current][dir];
            if (current & end == end) return steps + s;
        }
        steps += directions.len;
    }
}

fn lcm(a: usize, b: usize) usize {
    return (a * b) / std.math.gcd(a, b);
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var directions = std.ArrayList(u8).init(allocator);
    for (lines.next().?) |d| {
        if (d == 'L') directions.append(0) catch unreachable else directions.append(1) catch unreachable;
    }
    defer directions.deinit();

    var map: MapType = undefined;
    var starts = std.ArrayList([]const u8).init(allocator);
    defer starts.deinit();

    while (lines.next()) |line| {
        var e = std.mem.tokenizeScalar(u8, line, ' ');
        const from = e.next().?;
        _ = e.next(); // =
        const left = e.next().?[1..4];
        const right = e.next().?[0..3];
        if (from[2] == 'A') starts.append(from) catch unreachable;
        map[@intCast(hash(from))] = .{ hash(left), hash(right) };
    }

    res.p2 = 1;
    for (starts.items) |s| {
        const steps = walk(map, directions.items, s);
        if (std.mem.eql(u8, s, "AAA")) res.p1 = steps;
        res.p2 = lcm(res.p2, steps);
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

test "test1.1" {
    const test_input1 =
        \\RL
        \\
        \\AAA = (BBB, CCC)
        \\BBB = (DDD, EEE)
        \\CCC = (ZZZ, GGG)
        \\DDD = (DDD, DDD)
        \\EEE = (EEE, EEE)
        \\GGG = (GGG, GGG)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    const res = try solve(std.testing.allocator, test_input1);
    try std.testing.expectEqual(res.p1, 2);
}
test "test1.2" {
    const test_input1 =
        \\LLR
        \\
        \\AAA = (BBB, BBB)
        \\BBB = (AAA, ZZZ)
        \\ZZZ = (ZZZ, ZZZ)
    ;
    const res = try solve(std.testing.allocator, test_input1);
    try std.testing.expectEqual(res.p1, 6);
}

test "test2" {
    const test_input2 =
        \\LR
        \\
        \\DDA = (DDB, XXX)
        \\DDB = (XXX, DDZ)
        \\DDZ = (DDB, XXX)
        \\EEA = (EEB, XXX)
        \\EEB = (EEC, EEC)
        \\EEC = (EEZ, EEZ)
        \\EEZ = (EEB, EEB)
        \\XXX = (XXX, XXX)
    ;

    const res = try solve(std.testing.allocator, test_input2);
    try std.testing.expectEqual(res.p2, 6);
}
