const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

pub fn main() !void {
    var file = try std.fs.cwd().openFile("input", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        _ = line;
    }
}

test "test" {
}
