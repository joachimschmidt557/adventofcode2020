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

    testing.expectEqual(parsed[0][0], .open);
    testing.expectEqual(parsed[0][2], .tree);
}

const Slope = struct {
    right: u32,
    down: u32,
};

fn countTrees(map: []const []const Square, slope: Slope) u32 {
    var result: u32 = 0;
    var y: usize = 0;
    var x: usize = 0;

    while (y < map.len) : ({
        y += slope.down;
        x = (x + slope.right) % map[0].len;
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

    testing.expectEqual(@as(u32, 7), countTrees(parsed, Slope{
        .right = 3,
        .down = 1,
    }));
    testing.expectEqual(@as(u32, 2), countTrees(parsed, Slope{
        .right = 1,
        .down = 1,
    }));
    testing.expectEqual(@as(u32, 3), countTrees(parsed, Slope{
        .right = 5,
        .down = 1,
    }));
    testing.expectEqual(@as(u32, 4), countTrees(parsed, Slope{
        .right = 7,
        .down = 1,
    }));
    testing.expectEqual(@as(u32, 2), countTrees(parsed, Slope{
        .right = 1,
        .down = 2,
    }));
}

const slopes = [_]Slope{
    Slope{
        .right = 3,
        .down = 1,
    },
    Slope{
        .right = 1,
        .down = 1,
    },
    Slope{
        .right = 5,
        .down = 1,
    },
    Slope{
        .right = 7,
        .down = 1,
    },
    Slope{
        .right = 1,
        .down = 2,
    },
};

fn allSlopes(map: []const []const Square) u64 {
    var result: u64 = 1;

    for (slopes) |slope| {
        result *= countTrees(map, slope);
    }

    return result;
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

    const count = allSlopes(map);
    std.debug.print("all trees encountered on all slopes multiplied together: {}\n", .{count});
}
