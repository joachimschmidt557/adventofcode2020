const std = @import("std");
const testing = std.testing;

const Index = std.math.Log2Int(u26);

const input_file = "input06.txt";

fn parseOneDeclaration(line: []const u8) u26 {
    var result: u26 = 0;

    for (line) |c| {
        std.debug.assert(c >= 'a' and c <= 'z');
        const index = @intCast(Index, c - 'a');
        result |= @as(u26, 1) << index;
    }

    return result;
}

test "parse one declaration" {
    testing.expectEqual(@as(u26, 0b111), parseOneDeclaration("abc"));
}

fn nextDeclaration(reader: anytype) !?u26 {
    var result: ?u26 = null;

    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) break;
        if (result == null) result = 0;
        result.? |= parseOneDeclaration(line);
    }

    return result;
}

test "iterate over declarations" {
    const example =
        \\abc
        \\
        \\a
        \\b
        \\c
        \\
        \\ab
        \\ac
        \\
        \\a
        \\a
        \\a
        \\a
        \\
        \\b
    ;

    var fbs = std.io.fixedBufferStream(example);
    const reader = fbs.reader();

    testing.expectEqual(@as(?u26, 0b111), try nextDeclaration(reader));
    testing.expectEqual(@as(?u26, 0b111), try nextDeclaration(reader));
    testing.expectEqual(@as(?u26, 0b111), try nextDeclaration(reader));
    testing.expectEqual(@as(?u26, 0b1), try nextDeclaration(reader));
    testing.expectEqual(@as(?u26, 0b10), try nextDeclaration(reader));
    testing.expectEqual(@as(?u26, null), try nextDeclaration(reader));
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var sum: u32 = 0;

    const reader = file.reader();
    while (try nextDeclaration(reader)) |decl| {
        sum += @popCount(u26, decl);
    }

    std.debug.print("sum of the counts: {}\n", .{sum});
}
