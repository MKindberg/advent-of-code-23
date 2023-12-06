const std = @import("std");

const Result = struct { p1: usize, p2: usize };
const Colors = struct { red: usize, green: usize, blue: usize };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

fn parseLine(line: []const u8) Colors {
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    _ = it.next(); //game
    _ = it.next(); //game_num
    var col = Colors{ .red = 0, .green = 0, .blue = 0 };

    while (it.next()) |num| {
        const n = std.fmt.parseInt(usize, num, 10) catch unreachable;
        const c = it.next().?;
        switch (c[0]) {
            'r' => col.red = @max(col.red, n),
            'g' => col.green = @max(col.green, n),
            'b' => col.blue = @max(col.blue, n),
            else => unreachable,
        }
    }
    return col;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    _ = allocator;
    var res = Result{ .p1 = 0, .p2 = 0 };
    var game_num: usize = 0;
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        game_num += 1;
        const col = parseLine(line);
        if (col.red <= 12 and col.green <= 13 and col.blue <= 14) {
            res.p1 += game_num;
        }
        const score: usize = col.red * col.green * col.blue;
        res.p2 += score;
    }
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
    const res = try solve(alloc, input);
    std.debug.print("Part 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
}
