const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const Lens = struct { label: []const u8, len: u8 };

fn hash(str: []const u8) u64 {
    var res: usize = 0;
    for (str) |c| {
        res += c;
        res *= 17;
        res &= 0xFF;
    }
    return res;
}

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };
    var parts = std.mem.tokenizeScalar(u8, input, ',');

    var boxes: [256]std.ArrayList(Lens) = undefined;
    for (0..boxes.len) |i| boxes[i] = std.ArrayList(Lens).init(allocator);
    defer for (0..boxes.len) |i| boxes[i].deinit();

    while (parts.next()) |p| {
        std.debug.assert(p.len < 10);
        res.p1 += hash(p);
        if (std.mem.indexOfScalar(u8, p, '-')) |idx| {
            const label = p[0..idx];
            const h = hash(label);
            for (boxes[h].items, 0..) |lens, i| {
                if (std.mem.eql(u8, lens.label, label)) {
                    _ = boxes[h].orderedRemove(i);
                    break;
                }
            }
        } else if (std.mem.indexOfScalar(u8, p, '=')) |idx| {
            const label = p[0..idx];
            const len = p[idx + 1] - '0';
            const h = hash(label);
            for (boxes[h].items) |*lens| {
                if (std.mem.eql(u8, lens.label, label)) {
                    lens.*.len = len;
                    break;
                }
            } else try boxes[h].append(.{ .label = label, .len = len });
        } else unreachable;
    }
    for (boxes, 1..) |b, i| {
        for (b.items, 1..) |lens, j| {
            res.p2 += lens.len * i * j;
        }
    }
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

const test_input = "rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7";
test "test1" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p1, 1320);
}

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 145);
}
