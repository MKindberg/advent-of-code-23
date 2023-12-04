const std = @import("std");

const Result = struct { p1: usize, p2: usize };

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const alloc = gpa.allocator();

fn parseTicket(ticket: []const u8) usize {
    var buf: [20 * 8]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const fba_allocator = fba.allocator();

    var winning_nums = std.ArrayList(usize).initCapacity(fba_allocator, 20) catch unreachable;
    defer winning_nums.deinit();

    var wins: usize = 0;
    var nums = std.mem.tokenizeScalar(u8, ticket, ' ');
    _ = nums.next();
    _ = nums.next();
    while (nums.next()) |num| {
        if (num[0] == '|') {
            break;
        }
        winning_nums.appendAssumeCapacity(std.fmt.parseInt(usize, num, 10) catch unreachable);
    }
    while (nums.next()) |num| {
        const nm = std.fmt.parseInt(usize, num, 10) catch unreachable;
        for (winning_nums.items) |n| {
            if (nm == n) {
                wins += 1;
                break;
            }
        }
        // if (std.mem.indexOfScalar(usize, winning_nums.items, std.fmt.parseInt(usize, num, 10) catch unreachable) != null) {
        //     wins += 1;
        // }
    }
    return wins;
}

pub fn solve(input: []const u8) !Result {
    var buf: [300 * 8]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const fba_allocator = fba.allocator();

    var res = Result{ .p1 = 0, .p2 = 0 };
    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    const number_of_tickets: usize = std.mem.count(u8, input, "|");
    var tickets = std.ArrayList(usize).initCapacity(fba_allocator, number_of_tickets) catch unreachable;
    defer tickets.deinit();

    tickets.appendNTimesAssumeCapacity(1, number_of_tickets);

    var ticket_id: usize = 0;
    while (lines.next()) |line| : (ticket_id += 1) {
        var wins = parseTicket(line);

        res.p1 += if (wins > 0) std.math.pow(usize, 2, wins - 1) else 0;
        res.p2 += tickets.items[ticket_id];

        for (0..wins) |i| {
            const idx = ticket_id + 1 + i;
            tickets.items[idx] += tickets.items[ticket_id];
        }
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
    const res = try solve(input);
    std.debug.print("\nPart 1: {}\n", .{res.p1});
    std.debug.print("Part 2: {}\n", .{res.p2});
}

test "test1" {
    const test_input1 =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;

    const res = try solve(test_input1);
    try std.testing.expectEqual(res.p1, 13);
}

test "test2" {
    const test_input2 =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;
    const res = try solve(test_input2);
    try std.testing.expectEqual(res.p2, 30);
}
