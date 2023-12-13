const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };

fn equalColumns(map: [][]const u8, i: usize, j: usize) usize {
    var count: usize = 0;
    for (0..map.len) |k| {
        if (map[k][i] != map[k][j]) {
            count += 1;
            if (count > 1) return 2;
        }
    }
    return count;
}

fn equalRows(map: [][]const u8, i: usize, j: usize) usize {
    var count: usize = 0;
    for (0..map[0].len) |k| {
        if (map[i][k] != map[j][k]) {
            count += 1;
            if (count > 1) return 2;
        }
    }
    return count;
}
fn findVerticalSymmetry(map: [][]const u8, smudges: usize) ?usize {
    for (1..map[0].len) |i| {
        var j: usize = 1;
        var count: usize = 0;
        while (i >= j and i + j - 1 < map[0].len) {
            count += equalColumns(map, i - j, i + j - 1);
            if (count > smudges) {
                break;
            }
            j += 1;
        } else {
            if (count == smudges) return i;
        }
    }
    return null;
}
fn findHorizontalSymmetry(map: [][]const u8, smudges: usize) ?usize {
    for (1..map.len) |i| {
        var j: usize = 1;
        var count: usize = 0;
        while (i >= j and i + j - 1 < map.len) : (j += 1) {
            count += equalRows(map, i - j, i + j - 1);
            if (count > smudges) {
                break;
            }
        } else {
            if (count == smudges) return i;
        }
    }
    return null;
}

fn findSymmetry(map: [][]const u8, smudges: usize) ?usize {
    if (findHorizontalSymmetry(map, smudges)) |symmetry| {
        return symmetry * 100;
    } else if (findVerticalSymmetry(map, smudges)) |symmetry| {
        return symmetry;
    }
    return null;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    const in = std.mem.trim(u8, input, "\n");
    var lines = std.mem.splitScalar(u8, in, '\n');
    var map = std.ArrayList([]const u8).init(allocator);
    defer map.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) {
            res.p1 += findSymmetry(map.items, 0).?;
            res.p2 += findSymmetry(map.items, 1).?;

            map.clearRetainingCapacity();
            continue;
        }
        try map.append(line);
    }
    if (map.items.len > 0) {
        res.p1 += findSymmetry(map.items, 0).?;
        res.p2 += findSymmetry(map.items, 1).?;
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
    std.debug.print("\n --- Running with real input --- \n", .{});
    const res = try solve(allocator, input);
    std.debug.print("\nPart 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
}

const test_input =
    \\#.##..##.
    \\..#.##.#.
    \\##......#
    \\##......#
    \\..#.##.#.
    \\..##..##.
    \\#.#.##.#.
    \\
    \\#...##..#
    \\#....#..#
    \\..##..###
    \\#####.##.
    \\#####.##.
    \\..##..###
    \\#....#..#
;
test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 405);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 400);
}
