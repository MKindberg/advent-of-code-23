const std = @import("std");
const days = @import("days.zig").days;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

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
    var args = std.process.args();
    _ = args.skip();
    const d = std.fmt.parseInt(usize, args.next() orelse "0", 10) catch @panic("First arg must be an integer");
    const n = std.fmt.parseInt(usize, args.next() orelse "100", 10) catch @panic("Second arg must be an integer");
    var total_time: i128 = 0;
    if (d == 0) {
        inline for (days, 1..) |day, i| {
            var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer arena.deinit();

            const start = std.time.nanoTimestamp();
            const res = try day.solve(arena.allocator(), day.getInput());
            const stop = std.time.nanoTimestamp();
            const diff = stop - start;
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
    } else {
        inline for (days, 1..) |day, i| {
            if (i == d) {
                for (0..n) |_| {
                    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
                    defer arena.deinit();

                    const start = std.time.nanoTimestamp();
                    const res = try day.solve(arena.allocator(), day.getInput());
                    _ = res;
                    const stop = std.time.nanoTimestamp();
                    const diff = stop - start;
                    total_time += diff;
                }
                std.debug.print("Average time: ", .{});
                printTimeDiff(@divTrunc(total_time, n));
                std.debug.print("\n", .{});
            }
        }
    }
}
