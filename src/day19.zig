const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Range = struct { start: usize, stop: usize };
const Parts = struct {
    parts: [4]Range,

    fn idx(category: u8) usize {
        return switch (category) {
            'x' => 0,
            'm' => 1,
            'a' => 2,
            's' => 3,
            else => unreachable,
        };
    }

    fn sumValues(self: Parts) usize {
        return self.parts[0].start + self.parts[1].start + self.parts[2].start + self.parts[3].start;
    }
    fn sumRanges(self: Parts) usize {
        return (self.parts[0].stop - self.parts[0].start + 1) *
            (self.parts[1].stop - self.parts[1].start + 1) *
            (self.parts[2].stop - self.parts[2].start + 1) *
            (self.parts[3].stop - self.parts[3].start + 1);
    }

    fn parse(str: []const u8) Parts {
        var tokens = std.mem.tokenizeScalar(u8, str, ',');
        const x = std.fmt.parseInt(usize, tokens.next().?[2..], 10) catch unreachable;
        const m = std.fmt.parseInt(usize, tokens.next().?[2..], 10) catch unreachable;
        const a = std.fmt.parseInt(usize, tokens.next().?[2..], 10) catch unreachable;
        const s = std.fmt.parseInt(usize, tokens.next().?[2..], 10) catch unreachable;
        return Parts{
            .parts = .{
                Range{ .start = x, .stop = x },
                Range{ .start = m, .stop = m },
                Range{ .start = a, .stop = a },
                Range{ .start = s, .stop = s },
            },
        };
    }
};

const Condition = struct {
    category: ?u8 = null,
    operator: ?u8 = null,
    rhs: ?usize = null,
    res: []const u8,

    fn evaluate(self: Condition, parts: Parts) [2]?Parts {
        if (self.category) |cat| {
            const idx = Parts.idx(cat);
            var p = parts.parts[idx];
            const rhs = self.rhs.?;
            switch (self.operator.?) {
                '<' => {
                    if (p.stop < rhs) return .{ parts, null };
                    if (p.start < rhs) {
                        var p1 = parts;
                        var p2 = parts;
                        p1.parts[idx].stop = rhs - 1;
                        p2.parts[idx].start = rhs;
                        return .{ p1, p2 };
                    }
                },
                '>' => {
                    if (p.start > rhs) return .{ parts, null };
                    if (p.stop > rhs) {
                        var p1 = parts;
                        var p2 = parts;
                        p1.parts[idx].start = rhs + 1;
                        p2.parts[idx].stop = rhs;
                        return .{ p1, p2 };
                    }
                },
                else => unreachable,
            }
            return .{ null, parts };
        }
        return .{ parts, null };
    }

    fn parse(str: []const u8) Condition {
        if (std.mem.indexOf(u8, str, ":")) |delimiter| {
            return Condition{
                .category = str[0],
                .operator = str[1],
                .rhs = std.fmt.parseInt(usize, str[2..delimiter], 10) catch unreachable,
                .res = str[delimiter + 1 ..],
            };
        }
        return Condition{ .res = str };
    }
};

fn evaluateRec(comptime part: u8, conditions: std.StringHashMap(std.ArrayList(Condition)), parts: Parts, name: []const u8) usize {
    if (std.mem.eql(u8, name, "A")) if (part == 1) return parts.sumValues() else return parts.sumRanges();
    if (std.mem.eql(u8, name, "R")) return 0;
    var res: usize = 0;
    var current = parts;
    for (conditions.get(name).?.items) |c| {
        const new_parts = c.evaluate(current);
        if (new_parts[0]) |p| res += evaluateRec(part, conditions, p, c.res);
        if (new_parts[1]) |p| current = p else break;
    } else unreachable;
    return res;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.splitScalar(u8, input, '\n');
    var conditions = std.StringHashMap(std.ArrayList(Condition)).init(allocator);
    defer {
        var keys = conditions.keyIterator();
        while (keys.next()) |key| {
            conditions.get(key.*).?.deinit();
        }
        conditions.deinit();
    }
    while (lines.next()) |line| {
        if (line.len == 0) break;
        const delimiter = std.mem.indexOf(u8, line, "{").?;
        const name = line[0..delimiter];
        var conds = std.ArrayList(Condition).init(allocator);
        var tokens = std.mem.tokenizeScalar(u8, line[delimiter + 1 .. line.len - 1], ',');
        while (tokens.next()) |token| {
            conds.append(Condition.parse(token)) catch unreachable;
        }
        conditions.put(name, conds) catch unreachable;
    }

    while (lines.next()) |line| {
        var parts = Parts.parse(line[1 .. line.len - 1]);
        res.p1 += evaluateRec(1, conditions, parts, "in");
    }
    const all = Parts{ .parts = .{ .{ .start = 1, .stop = 4000 }, .{ .start = 1, .stop = 4000 }, .{ .start = 1, .stop = 4000 }, .{ .start = 1, .stop = 4000 } } };
    res.p2 = evaluateRec(2, conditions, all, "in");
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

const test_input =
    \\px{a<2006:qkq,m>2090:A,rfg}
    \\pv{a>1716:R,A}
    \\lnx{m>1548:A,A}
    \\rfg{s<537:gd,x>2440:R,A}
    \\qs{s>3448:A,lnx}
    \\qkq{x<1416:A,crn}
    \\crn{x>2662:A,R}
    \\in{s<1351:px,qqz}
    \\qqz{s>2770:qs,m<1801:hdj,R}
    \\gd{a>3333:R,R}
    \\hdj{m>838:A,pv}
    \\
    \\{x=787,m=2655,a=1222,s=2876}
    \\{x=1679,m=44,a=2067,s=496}
    \\{x=2036,m=264,a=79,s=2244}
    \\{x=2461,m=1339,a=466,s=291}
    \\{x=2127,m=1623,a=2188,s=1013}
;
test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 19114);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 167409079868000);
}
