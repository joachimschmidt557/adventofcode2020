const std = @import("std");
const testing = std.testing;

const input_file = "input01.txt";

fn getTwoNumbers(expense_report: []const u32) [2]u32 {
    return blk: for (expense_report) |x, i| {
        for (expense_report[i + 1 ..]) |y| {
            if (x + y == 2020) break :blk [_]u32{ x, y };
        }
    } else std.debug.panic("Assumption that input contains two numbers that add up to 2020 not met", .{});
}

test "getTwoNumbers" {
    const expense_report = [_]u32{
        1721,
        979,
        366,
        299,
        675,
        1456,
    };

    const two_numbers = getTwoNumbers(&expense_report);
    try testing.expectEqual([_]u32{ 1721, 299 }, two_numbers);
    try testing.expectEqual(@as(u32, 514579), two_numbers[0] * two_numbers[1]);
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

    const two_numbers = getTwoNumbers(expense_report.items);
    std.debug.print("two numbers: {} and {}\n", .{ two_numbers[0], two_numbers[1] });
    std.debug.print("multiplication: {}\n", .{two_numbers[0] * two_numbers[1]});
}
