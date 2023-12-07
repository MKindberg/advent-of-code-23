const std = @import("std");
const print = std.debug.print;

const Result = struct { p1: usize, p2: usize };
const HandType = enum {
    high_card,
    one_pair,
    two_pair,
    three_of_a_kind,
    full_house,
    four_of_a_kind,
    five_of_a_kind,

    fn countCards(cards: []const u8, comptime joker: bool) [5]usize {
        var count = std.mem.zeroes([5]usize);
        if (joker) {
            for (cards, &count) |card, *c| {
                c.* = if (card == 'J') 0 else std.mem.count(u8, cards, &([_]u8{card}));
            }
        } else {
            for (cards, &count) |card, *c| {
                c.* = std.mem.count(u8, cards, &([_]u8{card}));
            }
        }
        return count;
    }

    fn getHandType(hand_sum: usize) HandType {
        return switch (hand_sum) {
            5 * 5 => return .five_of_a_kind,
            4 * 4 + 1 => return .four_of_a_kind,
            3 * 3 + 2 * 2 => return .full_house,
            3 * 3 + 2 * 1 => return .three_of_a_kind,
            4 * 2 + 1 => return .two_pair,
            2 * 2 + 3 * 1 => return .one_pair,
            else => .high_card,
        };
    }

    fn init(cards: []const u8, comptime joker: bool) HandType {
        const count_arr = countCards(cards, joker);
        const count_vec: @Vector(count_arr.len, @TypeOf(count_arr[0])) = count_arr;
        const hand_sum: usize = @reduce(.Add, count_vec);
        const jokers = if (joker) std.mem.count(usize, &count_arr, &([_]usize{0})) else 0;
        const hand_type = getHandType(hand_sum + jokers);

        if (!joker) return hand_type;
        return switch (hand_type) {
            .five_of_a_kind => .five_of_a_kind,
            .four_of_a_kind => if (jokers == 1) .five_of_a_kind else .four_of_a_kind,
            .full_house => .full_house,
            .three_of_a_kind => switch (jokers) {
                0 => .three_of_a_kind,
                1 => .four_of_a_kind,
                2 => .five_of_a_kind,
                else => unreachable,
            },
            .two_pair => if (jokers == 1) .full_house else .two_pair,
            .one_pair => switch (jokers) {
                0 => .one_pair,
                1 => .three_of_a_kind,
                2 => .four_of_a_kind,
                3 => .five_of_a_kind,
                else => unreachable,
            },
            .high_card => switch (jokers) {
                0 => .high_card,
                1 => .one_pair,
                2 => .three_of_a_kind,
                3 => .four_of_a_kind,
                4 => .five_of_a_kind,
                5 => .five_of_a_kind,
                else => unreachable,
            },
        };
    }
};
const Hand = struct {
    score: [2]u64,
    bid: u64,

    fn card_score(card: u8, comptime joker: bool) u64 {
        return switch (card) {
            'T' => 10,
            'J' => if (joker) 1 else 11,
            'Q' => 12,
            'K' => 13,
            'A' => 14,
            else => card - '0',
        };
    }

    fn init(cards: []const u8, bid: u64) Hand {
        var score: [2]u64 = .{ 0, 0 };
        for (cards, 0..) |card, i| {
            const pos = std.math.pow(u64, 100, 4 - i);
            score[0] += card_score(card, false) * pos;
            score[1] += card_score(card, true) * pos;
        }
        const hand_type = .{ HandType.init(cards, false), HandType.init(cards, true) };

        score[0] += @intFromEnum(hand_type[0]) * std.math.pow(u64, 100, 5);
        score[1] += @intFromEnum(hand_type[1]) * std.math.pow(u64, 100, 5);
        return Hand{ .score = score, .bid = bid };
    }

    fn sort(_: void, a: Hand, b: Hand) bool {
        return std.sort.asc(u64)({}, a.score[0], b.score[0]);
    }
    fn sort2(_: void, a: Hand, b: Hand) bool {
        return std.sort.asc(u64)({}, a.score[1], b.score[1]);
    }
};

pub fn solve(allocator: std.mem.Allocator, input: []const u8) !Result {
    var res = Result{ .p1 = 0, .p2 = 0 };

    var hands = std.ArrayList(Hand).initCapacity(allocator, 1000) catch unreachable;
    defer hands.deinit();

    var lines = std.mem.tokenizeScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var l = std.mem.tokenizeScalar(u8, line, ' ');
        const cards_str = l.next().?;
        const bid = std.fmt.parseInt(u64, l.next().?, 10) catch unreachable;
        hands.append(Hand.init(cards_str, bid)) catch unreachable;
    }

    std.mem.sort(Hand, hands.items, {}, Hand.sort);
    for (hands.items, 1..) |h, r| {
        res.p1 += h.bid * r;
    }

    std.mem.sort(Hand, hands.items, {}, Hand.sort2);
    for (hands.items, 1..) |h, r| {
        res.p2 += h.bid * r;
    }
    return res;
}

pub fn getInput() []const u8 {
    return @embedFile("inputs/" ++ @typeName(@This()));
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
    \\32T3K 765
    \\T55J5 684
    \\KK677 28
    \\KTJJT 220
    \\QQQJA 483
;
// test "test1" {
//     const res = try solve(std.testing.allocator, test_input);
//     try std.testing.expectEqual(res.p1, 6440);
// }

test "test2" {
    const res = try solve(std.testing.allocator, test_input);
    try std.testing.expectEqual(res.p2, 5905);
}
