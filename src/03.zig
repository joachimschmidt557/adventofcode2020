const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const input_file = "input03.txt";

const Square = enum {
    open,
    tree,
};

fn parseMap(allocator: *Allocator, map: []const u8) ![]const []const Square {
    var result = std.ArrayList([]const Square).init(allocator);

    var iter = std.mem.tokenize(map, "\n");
    while (iter.next()) |row| {
        var parsed_row = try allocator.alloc(Square, row.len);
        for (row) |x, i| parsed_row[i] = switch (x) {
            '.' => .open,
            '#' => .tree,
            else => unreachable,
        };
        try result.append(parsed_row);
    }

    return result.toOwnedSlice();
}

fn freeMap(allocator: *Allocator, map: []const []const Square) void {
    for (map) |row| allocator.free(row);
    allocator.free(map);
}

test "parse" {
    const map =
        \\..##.......
        \\#...#...#..
        \\.#....#..#.
        \\..#.#...#.#
        \\.#...##..#.
        \\..#.##.....
        \\.#.#.#....#
        \\.#........#
        \\#.##...#...
        \\#...##....#
        \\.#..#...#.#
        \\
    ;
    const allocator = testing.allocator;
    const parsed = try parseMap(allocator, map);
    defer freeMap(allocator, parsed);

    try testing.expectEqual(parsed[0][0], .open);
    try testing.expectEqual(parsed[0][2], .tree);
}

fn countTrees(map: []const []const Square) u32 {
    var result: u32 = 0;
    var y: usize = 0;
    var x: usize = 0;

    while (y < map.len) : ({
        y += 1;
        x = (x + 3) % map[0].len;
    }) {
        const square = map[y][x];
        if (square == .tree) result += 1;
    }

    return result;
}

test "count trees" {
    const map =
        \\..##.......
        \\#...#...#..
        \\.#....#..#.
        \\..#.#...#.#
        \\.#...##..#.
        \\..#.##.....
        \\.#.#.#....#
        \\.#........#
        \\#.##...#...
        \\#...##....#
        \\.#..#...#.#
        \\
    ;
    const allocator = testing.allocator;
    const parsed = try parseMap(allocator, map);
    defer freeMap(allocator, parsed);

    try testing.expectEqual(@as(u32, 7), countTrees(parsed));
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    const reader = file.reader();
    const content = try reader.readAllAlloc(allocator, 4 * 1024 * 1024);
    defer allocator.free(content);

    const map = try parseMap(allocator, content);
    defer freeMap(allocator, map);

    const count = countTrees(map);
    std.debug.print("trees encountered: {}\n", .{count});
}
