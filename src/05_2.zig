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
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var seat_ids = std.ArrayList(u32).init(allocator);
    defer seat_ids.deinit();

    const reader = file.reader();
    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const seat = try Seat.fromDescription(line);
        const seat_id = seat.id();
        try seat_ids.append(seat_id);
    }

    std.sort.sort(u32, seat_ids.items, {}, comptime std.sort.asc(u32));

    const seat_id = for (seat_ids.items[0 .. seat_ids.items.len - 2]) |id, i| {
        if (seat_ids.items[i + 1] == id + 2) break id + 1;
    } else return error.SeatNotFound;

    std.debug.print("my seat id: {}\n", .{seat_id});
}
