const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Point = struct {
    x: usize,
    y: usize,
    z: usize,
    fn parse(str: []const u8) Point {
        var tok = std.mem.tokenizeScalar(u8, str, ',');
        return Point{
            .x = std.fmt.parseInt(usize, tok.next().?, 10) catch unreachable,
            .y = std.fmt.parseInt(usize, tok.next().?, 10) catch unreachable,
            .z = std.fmt.parseInt(usize, tok.next().?, 10) catch unreachable,
        };
    }
};
const Brick = struct {
    p1: Point,
    p2: Point,
    fn parse(str: []const u8) Brick {
        var del = std.mem.indexOfScalar(u8, str, '~').?;
        return Brick{
            .p1 = Point.parse(str[0..del]),
            .p2 = Point.parse(str[del + 1 ..]),
        };
    }
    fn overlapsX(self: Brick, other: Brick) bool {
        return (self.p1.x <= other.p1.x and other.p1.x <= self.p2.x) or
            (other.p1.x <= self.p1.x and self.p1.x <= other.p2.x);
    }
    fn overlapsY(self: Brick, other: Brick) bool {
        return (self.p1.y <= other.p1.y and other.p1.y <= self.p2.y) or
            (other.p1.y <= self.p1.y and self.p1.y <= other.p2.y);
    }
    fn drop(self: *Brick, bricks: []Brick) void {
        var z: usize = 1;
        for (bricks) |b| {
            if (self.overlapsX(b) and self.overlapsY(b) and self.p1.z > b.p2.z) {
                z = @max(z, b.p2.z + 1);
            }
        }
        self.p2.z = (self.p2.z - self.p1.z) + z;
        self.p1.z = z;
    }
    fn above(self: Brick, allocator: std.mem.Allocator, bricks: []Brick) std.ArrayList(Brick) {
        var res = std.ArrayList(Brick).init(allocator);
        for (bricks) |b| {
            if (self.p2.z + 1 == b.p1.z and self.overlapsX(b) and self.overlapsY(b)) {
                res.append(b) catch unreachable;
            }
        }
        return res;
    }
    fn below(self: Brick, allocator: std.mem.Allocator, bricks: []Brick) std.ArrayList(Brick) {
        var res = std.ArrayList(Brick).init(allocator);
        for (bricks) |b| {
            if (self.p1.z == b.p2.z + 1 and self.overlapsX(b) and self.overlapsY(b)) {
                res.append(b) catch unreachable;
            }
        }
        return res;
    }
};

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var bricks = std.ArrayList(Brick).init(allocator);
    defer bricks.deinit();
    while (lines.next()) |line| {
        try bricks.append(Brick.parse(line));
    }
    for (bricks.items) |*brick| {
        brick.drop(bricks.items);
    }

    var removable = std.AutoHashMap(Brick, void).init(allocator);
    defer removable.deinit();
    var non_removable = std.AutoHashMap(Brick, void).init(allocator);
    defer non_removable.deinit();
    for (bricks.items) |brick| {
        var above = brick.above(allocator, bricks.items);
        defer above.deinit();
        var below = brick.below(allocator, bricks.items);
        defer below.deinit();
        if (above.items.len == 0) try removable.put(brick, {});
        if (below.items.len > 1) {
            for (below.items) |b| {
                try removable.put(b, {});
            }
        } else if (below.items.len == 1) {
            try non_removable.put(below.items[0], {});
        }
    }
    var it = non_removable.keyIterator();
    while (it.next()) |brick| {
        _ = removable.remove(brick.*);
    }
    res.p1 = removable.count();
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

test "test_overlap" {
    const b1 = Brick{ .p1 = Point{ .x = 1, .y = 1, .z = 1 }, .p2 = Point{ .x = 3, .y = 3, .z = 1 } };
    const b2 = Brick{ .p1 = Point{ .x = 3, .y = 2, .z = 2 }, .p2 = Point{ .x = 4, .y = 4, .z = 2 } };
    try std.testing.expect(b2.overlapsX(b1));
    try std.testing.expect(b1.overlapsX(b2));
}

test "test1" {
    const test_input =
        \\1,0,1~1,2,1
        \\0,0,2~2,0,2
        \\0,2,3~2,2,3
        \\0,0,4~0,2,4
        \\2,0,5~2,2,5
        \\0,1,6~2,1,6
        \\1,1,8~1,1,9
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 5);
}

// test "test2" {
//     const test_input = "";
//     const res = try solve(std.testing.allocator, test_input);
//     try std.testing.expectEqual(res.p2, 0);
// }
