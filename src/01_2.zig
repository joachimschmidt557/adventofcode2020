const std = @import("std");
const testing = std.testing;

const input_file = "input01.txt";

fn getThreeNumbers(expense_report: []const u32) [3]u32 {
    return blk: for (expense_report) |x, i| {
        for (expense_report[i + 1 ..]) |y, j| {
            for (expense_report[i + j + 2 ..]) |z| {
                if (x + y + z == 2020) break :blk [_]u32{ x, y, z };
            }
        }
    } else std.debug.panic("Assumption that input contains three numbers that add up to 2020 not met", .{});
}

test "getThreeNumbers" {
    const expense_report = [_]u32{
        1721,
        979,
        366,
        299,
        675,
        1456,
    };

    const three_numbers = getThreeNumbers(&expense_report);
    try testing.expectEqual([_]u32{ 979, 366, 675 }, three_numbers);
    try testing.expectEqual(@as(u32, 241861950), three_numbers[0] * three_numbers[1] * three_numbers[2]);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;

    var expense_report = std.ArrayList(u32).init(allocator);
    defer expense_report.deinit();

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    const reader = file.reader();
    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const number = try std.fmt.parseInt(u32, line, 10);
        try expense_report.append(number);
    }

    const three_numbers = getThreeNumbers(expense_report.items);
    std.debug.print("three numbers: {}, {} and {}\n", .{ three_numbers[0], three_numbers[1], three_numbers[2] });
    std.debug.print("multiplication: {}\n", .{three_numbers[0] * three_numbers[1] * three_numbers[2]});
}
