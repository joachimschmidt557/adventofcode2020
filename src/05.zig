const std = @import("std");
const testing = std.testing;

const input_file = "input05.txt";

const Seat = struct {
    row: u32,
    column: u32,

    fn fromDescription(str: []const u8) !Seat {
        if (str.len != 10) return error.WrongLength;
        const row_desc = str[0..7];
        const column_desc = str[7..10];

        const row = blk: {
            var hi: u32 = 127;
            var lo: u32 = 0;

            for (row_desc) |c| {
                const mid = (hi + lo) / 2;
                switch (c) {
                    'F' => hi = mid,
                    'B' => lo = mid + 1,
                    else => return error.InvalidCharacter,
                }
            }

            break :blk hi;
        };

        const column = blk: {
            var hi: u32 = 7;
            var lo: u32 = 0;

            for (column_desc) |c| {
                const mid = (hi + lo) / 2;
                switch (c) {
                    'L' => hi = mid,
                    'R' => lo = mid + 1,
                    else => return error.InvalidCharacter,
                }
            }

            break :blk hi;
        };

        return Seat{
            .row = row,
            .column = column,
        };
    }

    fn id(self: Seat) u32 {
        return self.row * 8 + self.column;
    }
};

test "from description" {
    testing.expectEqual(Seat{ .row = 44, .column = 5 }, try Seat.fromDescription("FBFBBFFRLR"));
    testing.expectEqual(Seat{ .row = 70, .column = 7 }, try Seat.fromDescription("BFFFBBFRRR"));
    testing.expectEqual(Seat{ .row = 14, .column = 7 }, try Seat.fromDescription("FFFBBBFRRR"));
    testing.expectEqual(Seat{ .row = 102, .column = 4 }, try Seat.fromDescription("BBFFBBFRLL"));
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var max_seat_id: ?u32 = null;

    const reader = file.reader();
    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const seat = try Seat.fromDescription(line);
        const seat_id = seat.id();
        max_seat_id = if (max_seat_id) |current| std.math.max(current, seat_id) else seat_id;
    }

    std.debug.print("highest seat id: {}\n", .{max_seat_id});
}
