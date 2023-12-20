const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const PulseType = enum { high, low };
const Pulse = struct { type: PulseType, dest: []const u8, source: []const u8 };
const ModuleType = union(enum) { flip_flop: bool, broadcast: void, conjunction: std.StringHashMap(PulseType) };
const Module = struct { type: ModuleType, receivers: std.ArrayList([]const u8) };

fn lcm(a: usize, b: usize) usize {
    return (a * b) / std.math.gcd(a, b);
}
fn lcm4(factors: [4]usize) usize {
    var res: usize = 1;
    for (factors) |f| {
        res = lcm(res, f);
    }
    return res;
}

fn simulate(allocator: std.mem.Allocator, modules: *std.StringHashMap(Module)) Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var num_high: usize = 0;
    var num_low: usize = 0;
    var factors = std.mem.zeroes([4]usize);
    const Queue = std.TailQueue(Pulse);
    var queue: Queue = .{};
    var nodes = std.ArrayList(Queue.Node).initCapacity(allocator, 500) catch unreachable;
    defer nodes.deinit();
    outer: for (1..10000) |i| {
        defer nodes.clearRetainingCapacity();
        var node: Queue.Node = .{ .data = Pulse{ .type = .low, .dest = "roadcaster", .source = "button" } };
        nodes.appendAssumeCapacity(node);
        queue.append(&nodes.items[nodes.items.len - 1]);
        num_low += 1;
        while (queue.popFirst()) |n| {
            const pulse = n.data;
            var module = modules.getPtr(pulse.dest) orelse continue;
            var pulse_type: PulseType = switch (module.type) {
                .flip_flop => flip: {
                    if (pulse.type == .high) continue;
                    if (module.type.flip_flop) {
                        module.type.flip_flop = false;
                        break :flip .low;
                    }
                    module.type.flip_flop = true;
                    break :flip .high;
                },
                .broadcast => pulse.type,
                .conjunction => conj: {
                    module.type.conjunction.put(pulse.source, pulse.type) catch unreachable;
                    var keys = module.type.conjunction.keyIterator();
                    while (keys.next()) |key| {
                        var val = module.type.conjunction.get(key.*).?;
                        if (val == .low) break :conj .high;
                    }
                    break :conj .low;
                },
            };
            for (module.receivers.items) |rec| {
                node = .{ .data = Pulse{ .type = pulse_type, .dest = rec, .source = pulse.dest } };
                nodes.appendAssumeCapacity(node);
                queue.append(&nodes.items[nodes.items.len - 1]);
                if (i <= 1000) {
                    if (pulse_type == .high) num_high += 1 else num_low += 1;
                }
            }
            if (i == 1000) res.p1 = num_low * num_high;
            if (std.mem.eql(u8, pulse.dest, "dt") and pulse.type == .high) {
                var keys = module.type.conjunction.keyIterator();
                for (0..4) |j| {
                    var key = keys.next().?;
                    var val = module.type.conjunction.get(key.*).?;
                    if (val == .high) factors[j] = i;
                }
                for (0..4) |j| {
                    if (factors[j] == 0) break;
                } else {
                    res.p2 = lcm4(factors);
                    break :outer;
                }
            }
        }
    }
    return res;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    var modules = std.StringHashMap(Module).init(allocator);
    defer {
        var keys = modules.keyIterator();
        while (keys.next()) |key| {
            var val = modules.get(key.*).?;
            if (val.type == .conjunction) val.type.conjunction.deinit();
            val.receivers.deinit();
        }
        modules.deinit();
    }
    var conj_mods = std.ArrayList([]const u8).init(allocator);
    defer conj_mods.deinit();
    while (lines.next()) |line| {
        var tokens = std.mem.tokenizeSequence(u8, line, " -> ");
        const mod = tokens.next().?;
        const name = mod[1..];
        const module_type = switch (mod[0]) {
            '%' => ModuleType{ .flip_flop = false },
            '&' => blk: {
                conj_mods.append(name) catch unreachable;
                break :blk ModuleType{ .conjunction = std.StringHashMap(PulseType).init(allocator) };
            },
            'b' => ModuleType.broadcast,
            else => unreachable,
        };

        var receivers = std.ArrayList([]const u8).init(allocator);
        var rec_tokens = std.mem.tokenizeSequence(u8, tokens.next().?, ", ");
        while (rec_tokens.next()) |rec| {
            receivers.append(rec) catch unreachable;
        }
        modules.put(name, Module{ .type = module_type, .receivers = receivers }) catch unreachable;
    }

    var keys = modules.keyIterator();
    while (keys.next()) |key| {
        var module = modules.get(key.*).?;
        for (module.receivers.items) |rec| {
            for (conj_mods.items) |c| {
                if (std.mem.eql(u8, rec, c)) modules.getPtr(c).?.type.conjunction.put(key.*, .low) catch unreachable;
            }
        }
    }

    res = simulate(allocator, &modules);

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

test "test1.1" {
    const test_input =
        \\broadcaster -> a, b, c
        \\%a -> b
        \\%b -> c
        \\%c -> inv
        \\&inv -> a
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 32000000);
}
test "test1.2" {
    const test_input =
        \\broadcaster -> a
        \\%a -> inv, con
        \\&inv -> b
        \\%b -> con
        \\&con -> output
    ;
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 11687500);
}
