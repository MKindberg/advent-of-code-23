const std = @import("std");

const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Range = struct {
    start: usize,
    end: usize,
    const Self = @This();
    fn init(start: usize, end: usize) Self {
        return .{ .start = start, .end = end };
    }
    fn overlaps(self: Self, other: Self) bool {
        if (self.start < other.start) {
            if (self.end > other.end) return true;
            if (self.end > other.start) return true;
        } else if (self.start >= other.start) {
            if (self.end < other.end) return true;
            if (self.start < other.end) return true;
        }
        return false;
    }

    fn split(self: Self, overlap: Self) ?[3]?Range {
        if (self.overlaps(overlap)) {
            const one = if (overlap.start < self.start) Range.init(overlap.start, self.start) else null;
            const two = if (overlap.start < self.start) Range.init(self.start, @min(self.end, overlap.end)) else Range.init(overlap.start, @min(self.end, overlap.end));
            const three = if (overlap.end > self.end) Range.init(self.end, overlap.end) else null;

            return .{
                one,
                two,
                three,
            };
        }
        return null;
    }
    fn isEmpty(self: Self) bool {
        return self.start == self.end;
    }
    fn print(self: Self) void {
        std.debug.print("({},{})\n", .{ self.start, self.end });
    }
};
const Map = struct { from: Range, to: Range };

fn sortMapsStart(context: void, a: Map, b: Map) bool {
    return std.sort.asc(usize)(context, a.from.start, b.from.start);
}
fn sortMapsEnd(context: void, a: Map, b: Map) bool {
    return std.sort.asc(usize)(context, a.from.start, b.from.start);
}

fn parseSeeds(allocator: std.mem.Allocator, line: []const u8) std.ArrayList(Range) {
    var seeds = std.ArrayList(Range).init(allocator);
    var parts = std.mem.tokenizeScalar(u8, line, ' ');
    _ = parts.next();
    while (parts.next()) |part| {
        const s = std.fmt.parseInt(usize, part, 10) catch unreachable;
        seeds.append(.{ .start = s, .end = s + 1 }) catch unreachable;
    }
    return seeds;
}

fn parseSeeds2(allocator: std.mem.Allocator, line: []const u8) std.ArrayList(Range) {
    var seeds = std.ArrayList(Range).init(allocator);
    var parts = std.mem.tokenizeScalar(u8, line, ' ');
    _ = parts.next();
    while (parts.next()) |part| {
        const s = std.fmt.parseInt(usize, part, 10) catch unreachable;
        const l = std.fmt.parseInt(usize, parts.next().?, 10) catch unreachable;
        seeds.append(.{ .start = s, .end = s + l }) catch unreachable;
    }
    return seeds;
}

fn parseMap(allocator: std.mem.Allocator, lines: *std.mem.TokenIterator(u8, .scalar)) std.ArrayList(Map) {
    var maps = std.ArrayList(Map).init(allocator);
    while (lines.next()) |line| {
        if (!std.ascii.isDigit(line[0])) break;
        var parts = std.mem.tokenizeScalar(u8, line, ' ');
        const to = std.fmt.parseInt(usize, parts.next().?, 10) catch unreachable;
        const from = std.fmt.parseInt(usize, parts.next().?, 10) catch unreachable;
        const len = std.fmt.parseInt(usize, parts.next().?, 10) catch unreachable;
        maps.append(Map{ .from = Range{ .start = from, .end = from + len }, .to = Range{ .start = to, .end = to + len } }) catch unreachable;
    }
    std.mem.sort(Map, maps.items, {}, sortMapsStart);
    return maps;
}

fn transform(allocator: std.mem.Allocator, maps: std.ArrayList(Map), item: Range) std.ArrayList(Range) {
    var i = item;
    var res = std.ArrayList(Range).init(allocator);
    for (maps.items) |map| {
        if (map.from.split(i)) |splits| {
            if (splits[0]) |r| {
                res.append(r) catch unreachable;
            }
            const r_start = map.to.start + splits[1].?.start - map.from.start;
            res.append(Range{ .start = r_start, .end = r_start + splits[1].?.end - splits[1].?.start }) catch unreachable;
            if (splits[2]) |r| i = r else return res;
        }
    }
    res.append(i) catch unreachable;
    return res;
}

fn transformSeeds(allocator: std.mem.Allocator, maps: std.ArrayList(Map), seeds: std.ArrayList(Range)) std.ArrayList(Range) {
    var new_seed = std.ArrayList(Range).init(allocator);
    for (seeds.items) |seed| {
        var t = transform(allocator, maps, seed);
        defer t.deinit();
        new_seed.appendSlice(t.items) catch unreachable;
    }
    seeds.deinit();
    return new_seed;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');

    var maps: [7]std.ArrayList(Map) = undefined;
    defer for (maps) |m| {
        m.deinit();
    };
    const seed_line = lines.next().?;
    var seeds = parseSeeds(allocator, seed_line);
    defer seeds.deinit();
    var seeds2 = parseSeeds2(allocator, seed_line);
    defer seeds2.deinit();
    _ = lines.next();
    for (0..7) |i| {
        maps[i] = parseMap(allocator, &lines);
        seeds = transformSeeds(allocator, maps[i], seeds);
        seeds2 = transformSeeds(allocator, maps[i], seeds2);
    }
    res.p1 = seeds.items[0].start;
    for (seeds.items) |seed| {
        res.p1 = @min(res.p1, seed.start);
    }
    res.p2 = seeds2.items[0].start;
    for (seeds2.items) |seed| {
        res.p2 = @min(res.p2, seed.start);
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

test "test get_overlap" {
    const r = Range.init(2, 5);
    // Complete overlap
    try std.testing.expectEqual(r.overlaps(Range.init(3, 4)), true);
    try std.testing.expectEqual(r.overlaps(Range.init(2, 4)), true);
    try std.testing.expectEqual(r.overlaps(Range.init(2, 5)), true);
    try std.testing.expectEqual(r.overlaps(Range.init(3, 5)), true);
    try std.testing.expectEqual(r.overlaps(Range.init(1, 7)), true);

    // Starting overlap
    try std.testing.expectEqual(r.overlaps(Range.init(1, 4)), true);
    try std.testing.expectEqual(r.overlaps(Range.init(1, 5)), true);
    //
    // Ending overlap
    try std.testing.expectEqual(r.overlaps(Range.init(2, 7)), true);
    try std.testing.expectEqual(r.overlaps(Range.init(3, 7)), true);

    // No overlap
    try std.testing.expectEqual(r.overlaps(Range.init(0, 1)), false);
    try std.testing.expectEqual(r.overlaps(Range.init(0, 2)), false);
    try std.testing.expectEqual(r.overlaps(Range.init(5, 6)), false);
    try std.testing.expectEqual(r.overlaps(Range.init(6, 7)), false);
}

test "test split" {
    const r = Range.init(2, 5);

    // Complete overlap
    try std.testing.expectEqual(r.split(Range.init(3, 4)), .{ null, Range.init(3, 4), null });
    try std.testing.expectEqual(r.split(Range.init(2, 4)), .{ null, Range.init(2, 4), null });
    try std.testing.expectEqual(r.split(Range.init(2, 5)), .{ null, Range.init(2, 5), null });
    try std.testing.expectEqual(r.split(Range.init(3, 5)), .{ null, Range.init(3, 5), null });
    try std.testing.expectEqual(r.split(Range.init(1, 7)), .{ Range.init(1, 2), Range.init(2, 5), Range.init(5, 7) });

    // Starting overlap
    try std.testing.expectEqual(r.split(Range.init(1, 4)), .{ Range.init(1, 2), Range.init(2, 4), null });
    try std.testing.expectEqual(r.split(Range.init(1, 5)), .{ Range.init(1, 2), Range.init(2, 5), null });
    //
    // // Ending overlap
    try std.testing.expectEqual(r.split(Range.init(2, 7)), .{ null, Range.init(2, 5), Range.init(5, 7) });
    try std.testing.expectEqual(r.split(Range.init(3, 7)), .{ null, Range.init(3, 5), Range.init(5, 7) });
}

test "test transform" {
    var m = std.ArrayList(Map).init(std.testing.allocator);
    defer m.deinit();
    try m.append(Map{ .from = Range.init(2, 4), .to = Range.init(3, 6) });
    try m.append(Map{ .from = Range.init(5, 6), .to = Range.init(9, 10) });
    const r = Range.init(1, 7);
    const res = transform(std.testing.allocator, m, r);
    defer res.deinit();
}

const test_input =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
;

test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 35);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 46);
}
