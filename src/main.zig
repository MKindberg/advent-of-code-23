const std = @import("std");
const days = @import("days.zig").days;
const colors = true;

const skip = [_]usize{ 17, 18 };

fn setColor(color: std.io.tty.Color) void {
    if (colors) {
        std.io.tty.Config.setColor(.escape_codes, std.io.getStdErr(), color) catch {};
    }
}

fn printTimeDiff(diff: i128) void {
    var d = diff;
    defer setColor(.reset);
    if (d > std.time.ns_per_s) {
        setColor(.red);
        const sec = @divFloor(d, std.time.ns_per_s);
        std.debug.print("{}s ", .{sec});
        d -= sec * std.time.ns_per_s;
        if (sec > 10) return;
    }
    if (d > std.time.ns_per_ms) {
        setColor(.yellow);
        const ms = @divFloor(d, std.time.ns_per_ms);
        std.debug.print("{}ms ", .{ms});
        d -= ms * std.time.ns_per_ms;
        if (ms > 10) return;
    }
    if (d > std.time.ns_per_us) {
        setColor(.green);
        const us = @divFloor(d, std.time.us_per_ms);
        std.debug.print("{}μs ", .{us});
        d -= us * std.time.ns_per_us;
        if (us > 10) return;
    }
    setColor(.cyan);
    std.debug.print("{}ns ", .{d});
}

pub fn main() !void {
    var args = std.process.args();
    _ = args.skip();
    const d = std.fmt.parseInt(usize, args.next() orelse "0", 10) catch @panic("First arg must be an integer");
    const n = std.fmt.parseInt(usize, args.next() orelse "1", 10) catch @panic("Second arg must be an integer");
    var total_time: i128 = 0;
    if (d == 0) {
        outer: inline for (days, 1..) |day, i| {
            inline for (skip) |s| {
                if (i == s) {
                    std.debug.print("Day {}: -\n", .{i});
                    continue :outer;
                }
            }
            var test_time: i128 = 0;
            for (0..n) |_| {
                var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
                defer arena.deinit();

                const start = std.time.nanoTimestamp();
                _ = try day.solve(arena.allocator(), day.getInput());
                const stop = std.time.nanoTimestamp();
                const diff = stop - start;
                test_time += diff;
            }
            test_time = @divFloor(test_time, n);
            total_time += test_time;
            std.debug.print("Day {}: ", .{i});
            printTimeDiff(test_time);
            var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer arena.deinit();
            var res = try day.solve(arena.allocator(), day.getInput());
            if (res.p2 == 0) std.debug.print("(no part 2)\n", .{}) else std.debug.print("\n", .{});
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
