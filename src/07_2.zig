const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const input_file = "input07.txt";

const Child = struct {
    color: []const u8,
    amount: u32,
};

const Rules = std.StringHashMap([]const Child);

fn parseRules(allocator: *Allocator, reader: anytype) !Rules {
    var result = Rules.init(allocator);

    var buf: [4 * 1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const line_without_dot = line[0 .. line.len - 1];
        var iter = std.mem.split(line_without_dot, " contain ");
        const head = iter.next() orelse return error.FormatError;
        const tail = iter.next() orelse return error.FormatError;

        // parent
        const parent = try allocator.dupe(u8, head[0 .. head.len - 5]);

        // children
        var children = std.ArrayList(Child).init(allocator);
        if (!std.mem.eql(u8, tail, "no other bags")) {
            var tail_iter = std.mem.split(tail, ", ");
            while (tail_iter.next()) |item| {
                const trailing_bytes_to_remove: usize = if (std.mem.endsWith(u8, item, " bags")) 5 else if (std.mem.endsWith(u8, item, " bag")) 4 else return error.UnexpectedEnd;
                const first_space = std.mem.indexOfScalar(u8, item, ' ').?;
                const color = item[first_space + 1 .. item.len - trailing_bytes_to_remove];
                const amount = try std.fmt.parseInt(u32, item[0..first_space], 10);

                try children.append(Child{
                    .color = try allocator.dupe(u8, color),
                    .amount = amount,
                });
            }
        }

        try result.put(parent, children.toOwnedSlice());
    }

    return result;
}

fn freeRules(allocator: *Allocator, rules: *Rules) void {
    var iter = rules.iterator();
    while (iter.next()) |kv| {
        allocator.free(kv.key);
        for (kv.value) |x| allocator.free(x.color);
        allocator.free(kv.value);
    }
    rules.deinit();
}

test "parse rules" {
    const allocator = std.testing.allocator;
    const rules =
        \\light red bags contain 1 bright white bag, 2 muted yellow bags.
        \\dark orange bags contain 3 bright white bags, 4 muted yellow bags.
        \\bright white bags contain 1 shiny gold bag.
        \\muted yellow bags contain 2 shiny gold bags, 9 faded blue bags.
        \\shiny gold bags contain 1 dark olive bag, 2 vibrant plum bags.
        \\dark olive bags contain 3 faded blue bags, 4 dotted black bags.
        \\vibrant plum bags contain 5 faded blue bags, 6 dotted black bags.
        \\faded blue bags contain no other bags.
        \\dotted black bags contain no other bags.
        \\
    ;

    var fbs = std.io.fixedBufferStream(rules);
    const reader = fbs.reader();

    var parsed = try parseRules(allocator, reader);
    defer freeRules(allocator, &parsed);

    try testing.expectEqualSlices(u8, (parsed.get("light red").?)[0].color, "bright white");
    try testing.expectEqual(@as(u32, 1), (parsed.get("light red").?)[0].amount);
    try testing.expectEqualSlices(u8, (parsed.get("light red").?)[1].color, "muted yellow");
    try testing.expectEqual(@as(u32, 2), (parsed.get("light red").?)[1].amount);
    try testing.expectEqualSlices(u8, (parsed.get("bright white").?)[0].color, "shiny gold");
    try testing.expectEqual(@as(usize, 0), (parsed.get("faded blue").?).len);
}

fn countInnerBags(rules: Rules, target_color: []const u8) u32 {
    var sum: u32 = 0;

    const children = rules.get(target_color).?;
    for (children) |child| {
        sum += child.amount * (1 + countInnerBags(rules, child.color));
    }

    return sum;
}

test "count inner bags" {
    const allocator = std.testing.allocator;
    const rules =
        \\shiny gold bags contain 2 dark red bags.
        \\dark red bags contain 2 dark orange bags.
        \\dark orange bags contain 2 dark yellow bags.
        \\dark yellow bags contain 2 dark green bags.
        \\dark green bags contain 2 dark blue bags.
        \\dark blue bags contain 2 dark violet bags.
        \\dark violet bags contain no other bags.
        \\
    ;

    var fbs = std.io.fixedBufferStream(rules);
    const reader = fbs.reader();

    var parsed = try parseRules(allocator, reader);
    defer freeRules(allocator, &parsed);

    try testing.expectEqual(@as(u32, 126), countInnerBags(parsed, "shiny gold"));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();
    const reader = file.reader();

    var parsed = try parseRules(allocator, reader);
    defer freeRules(allocator, &parsed);

    std.debug.warn("inner bags: {}\n", .{countInnerBags(parsed, "shiny gold")});
}
