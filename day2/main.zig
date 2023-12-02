const std = @import("std");

const colors = struct { red: usize, green: usize, blue: usize };

fn parseLine(line: []u8) colors {
    var it = std.mem.tokenizeScalar(u8, line, ' ');
    _ = it.next(); //game
    _ = it.next(); //game_num
    var col = colors{ .red = 0, .green = 0, .blue = 0 };

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

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var p1_score: usize = 0;
    var p2_score: usize = 0;
    var game_num: usize = 0;
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        game_num += 1;
        const col = parseLine(line);
        if (col.red <= 12 and col.green <= 13 and col.blue <= 14) {
            p1_score += game_num;
        }
        const score: usize = col.red * col.green * col.blue;
        p2_score += score;
    }
    std.debug.print("Part 1: {}\n", .{p1_score});
    std.debug.print("Part 2: {}\n", .{p2_score});
}

test "test" {}
