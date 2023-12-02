const std = @import("std");
const days = @import("days.zig").days;

fn printTimeDiff(diff: i128) void {
    var d = diff;
    if (d > std.time.ns_per_s) {
        const sec = @divFloor(d, std.time.ns_per_s);
        std.debug.print("{}s ", .{sec});
        d -= sec * std.time.ns_per_s;
    }
    if (d > std.time.ns_per_ms) {
        const ms = @divFloor(d, std.time.ns_per_ms);
        std.debug.print("{}ms ", .{ms});
        d -= ms * std.time.ns_per_ms;
    }
    std.debug.print("{}us\n", .{@divFloor(d, std.time.ns_per_us)});
}

pub fn main() !void {
    var total_time: i128 = 0;
    inline for (days, 1..) |day, i| {
        const start = std.time.nanoTimestamp();
        const res = try day.solve(day.getInput());
        const stop = std.time.nanoTimestamp();
        const diff = stop-start;
        total_time += diff;

        std.debug.print("Day {}\n", .{i});
        std.debug.print("    Part 1: {}\n", .{res.p1});
        std.debug.print("    Part 2: {}\n", .{res.p2});
        std.debug.print("    Time: ", .{});
        printTimeDiff(diff);
        std.debug.print("\n", .{});
    }
    std.debug.print("Total time: ", .{});
    printTimeDiff(total_time);
    std.debug.print("\n", .{});
}
