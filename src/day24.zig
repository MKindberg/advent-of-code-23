const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Pos = struct { x: f64, y: f64, z: f64 };
const Vel = struct { x: f64, y: f64, z: f64 };
const Hail = struct { p: Pos, v: Vel };

var min: f64 = 200000000000000;
var max: f64 = 400000000000000;

// x = p.x + v.x*t
// t = (x - p.x) / v.x
// y = p.y + v.y*t
// t = (y - p.y) / v.y
// (x - p.x) / v.x = (y - p.y) / v.y
// (x - p.x) = ((y - p.y) / v.y) * v.x
// x = ((y - p.y) / v.y) * v.x + p.x
// y = ((x - p.x) / v.x) * v.y + p.y

// ((y - p2.y) / v2.y) * v2.x + p2.x = ((y - p1.y) / v1.y) * v1.x + p1.x
// (y - p2.y) / v2.y = (((y - p1.y) / v1.y) * v1.x + p1.x - p2.x)/v2.x
// y = ((((y - p1.y) / v1.y) * v1.x + p1.x - p2.x)/v2.x)*v2.y + p2.y
// x = ((((x - p1.x) / v1.x) * v1.y + p1.y - p2.y)/v2.y)*v2.x + p2.x

// y = ((((y - p1.y) / v1.y) * v1.x + p1.x - p2.x)/v2.x)*v2.y + p2.y
fn intersection(h1: Hail, h2: Hail) ?Pos {
    const y = y_res: {
        const k1 = (h1.p.x - h2.p.x) * h2.v.y / h2.v.x + h2.p.y;
        const k2 = -(h1.p.y * h1.v.x * h2.v.y) / (h1.v.y * h2.v.x);
        const k3 = k2 + k1;
        const k4 = (h1.v.x * h2.v.y) / (h1.v.y * h2.v.x);
        if (1 - k4 == 0) return null;
        const yy = k3 / (1 - k4);
        if ((yy - h1.p.y) / h1.v.y < 0 or (yy - h2.p.y) / h2.v.y < 0) return null; // t
        break :y_res yy;
    };

    const x = x_res: {
        const k1 = (h1.p.y - h2.p.y) * h2.v.x / h2.v.y + h2.p.x;
        const k2 = -(h1.p.x * h1.v.y * h2.v.x) / (h1.v.x * h2.v.y);
        const k3 = k2 + k1;
        const k4 = (h1.v.y * h2.v.x) / (h1.v.x * h2.v.y);
        if (1 - k4 == 0) return null;
        const xx = k3 / (1 - k4);
        if ((xx - h1.p.x) / h1.v.x < 0 or (xx - h2.p.x) / h2.v.x < 0) return null; // t
        break :x_res xx;
    };

    return Pos{ .x = x, .y = y, .z = 0 };
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var hails = std.ArrayList(Hail).init(allocator);
    defer hails.deinit();
    while (lines.next()) |line| {
        var parts = std.mem.tokenizeSequence(u8, line, " @ ");
        var pos_str = std.mem.tokenizeSequence(u8, parts.next().?, ", ");
        var vel_str = std.mem.tokenizeSequence(u8, parts.next().?, ", ");
        hails.append(Hail{
            .p = Pos{
                .x = std.fmt.parseFloat(f64, pos_str.next().?) catch unreachable,
                .y = std.fmt.parseFloat(f64, pos_str.next().?) catch unreachable,
                .z = std.fmt.parseFloat(f64, pos_str.next().?) catch unreachable,
            },
            .v = Vel{
                .x = std.fmt.parseFloat(f64, vel_str.next().?) catch unreachable,
                .y = std.fmt.parseFloat(f64, vel_str.next().?) catch unreachable,
                .z = std.fmt.parseFloat(f64, vel_str.next().?) catch unreachable,
            },
        }) catch unreachable;
    }

    for (0..hails.items.len) |i| {
        for (i + 1..hails.items.len) |j| {
            if (intersection(hails.items[i], hails.items[j])) |pos| {
                if (pos.x >= min and pos.x <= max and pos.y >= min and pos.y <= max) {
                    res.p1 += 1;
                }
            }
        }
    }

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
    std.debug.print("\nPart 1: {}\n", .{res.p1}); // 22931 too high
    std.debug.print("Part 2: {}\n", .{res.p2});
}

test "test_intersect" {
    const h1 = Hail{ .p = Pos{ .x = 19, .y = 13, .z = 0 }, .v = Vel{ .x = -2, .y = 1, .z = 0 } };
    const h2 = Hail{ .p = Pos{ .x = 18, .y = 19, .z = 0 }, .v = Vel{ .x = -1, .y = -1, .z = 0 } };
    const res = intersection(h1, h2).?;
    try std.testing.expectApproxEqAbs(res.x, 14.333, 0.001);
    try std.testing.expectApproxEqAbs(res.y, 15.333, 0.001);
}

test "test1" {
    const test_input =
        \\19, 13, 30 @ -2, 1, -2
        \\18, 19, 22 @ -1, -1, -2
        \\20, 25, 34 @ -2, -2, -4
        \\12, 31, 28 @ -1, -2, -1
        \\20, 19, 15 @ 1, -5, -3
    ;
    min = 7;
    max = 27;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 2);
}

// test "test2" {
//     const test_input = "";
//     const res = try solve(std.testing.allocator, test_input);
//     try std.testing.expectEqual(res.p2, 0);
// }
