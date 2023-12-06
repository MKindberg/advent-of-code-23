const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

fn raceWins(len: usize, goal: usize) usize {
    const t: f64 = @floatFromInt(len);
    const r: f64 = @floor(t / 2 - @sqrt(std.math.pow(f64, -t / 2, 2) - @as(f64, @floatFromInt(goal)))) + 1;
    const h: usize = @intFromFloat(r);
    return len + 1 - 2 * h;
}

fn mergeNum(nums: []usize) usize {
    var buf: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const fba_allocator = fba.allocator();

    var str_num: []u8 = "";
    for (nums) |n| {
        str_num = std.fmt.allocPrint(fba_allocator, "{s}{}", .{ str_num, n }) catch unreachable;
    }
    return std.fmt.parseInt(usize, str_num, 10) catch unreachable;
}

pub fn solve(input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var time: [4]usize = undefined;
    var dist: [4]usize = undefined;
    var races: usize = 0;

    var time_line = std.mem.tokenizeScalar(u8, lines.next().?, ' ');
    var dist_line = std.mem.tokenizeScalar(u8, lines.next().?, ' ');
    _ = time_line.next();
    _ = dist_line.next();
    while (time_line.next()) |t| {
        const d = dist_line.next().?;
        time[races] = std.fmt.parseInt(usize, t, 10) catch unreachable;
        dist[races] = std.fmt.parseInt(usize, d, 10) catch unreachable;
        races += 1;
    }
    res.p1 = 1;
    for (0..races) |r| {
        res.p1 *= raceWins(time[r], dist[r]);
    }

    const time2 = mergeNum(time[0..races]);
    const dist2 = mergeNum(dist[0..races]);

    res.p2 = raceWins(time2, dist2);

    return res;
}

pub fn getInput() []const u8 {
    return @embedFile("inputs/" ++ @typeName(@This()));
}

pub fn readInput(path: []const u8) []const u8 {
    const file = std.fs.cwd().openFile(path, .{}) catch @panic("could not open file");
    return file.readToEndAlloc(alloc, file.getEndPos() catch @panic("could not read file")) catch @panic("could not read file");
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();
    const input = if (args.next()) |path| readInput(path) else getInput();
    const res = try solve(input);
    std.debug.print("\nPart 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
}

test "test race" {
    try std.testing.expectEqual(raceWins(7, 9), 4);
}

test "test1" {
    const test_input1 =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;

    const res = try solve(test_input1);
    try std.testing.expectEqual(res.p1, 288);
}

test "test2" {
    const test_input2 =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;
    const res = try solve(test_input2);
    try std.testing.expectEqual(res.p2, 71503);
}
