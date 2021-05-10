const std = @import("std");
const testing = std.testing;

const input_file = "input02.txt";

const PasswordPolicy = struct {
    min: u32,
    max: u32,
    char: u8,
};

fn parsePasswordPolicy(policy: []const u8) !PasswordPolicy {
    var iter = std.mem.split(policy, " ");
    const min_max = iter.next() orelse return error.FormatError;
    const char = iter.next() orelse return error.FormatError;

    var iter_min_max = std.mem.split(min_max, "-");
    const min = iter_min_max.next() orelse return error.FormatError;
    const max = iter_min_max.next() orelse return error.FormatError;

    return PasswordPolicy{
        .min = try std.fmt.parseInt(u32, min, 10),
        .max = try std.fmt.parseInt(u32, max, 10),
        .char = if (char.len == 1) char[0] else return error.CharacterTooLong,
    };
}

test "parsePasswordPolicy" {
    const policy = "1-3 a";
    const parsed = try parsePasswordPolicy(policy);

    try testing.expectEqual(parsed.min, 1);
    try testing.expectEqual(parsed.max, 3);
    try testing.expectEqual(parsed.char, 'a');
}

const Line = struct {
    policy: PasswordPolicy,
    password: []const u8,

    pub fn isValid(self: Line) bool {
        var count: u32 = 0;
        for (self.password) |x| {
            if (x == self.policy.char) count += 1;
        }
        return count >= self.policy.min and count <= self.policy.max;
    }
};

fn parseLine(line: []const u8) !Line {
    var iter = std.mem.split(line, ":");
    const policy = iter.next() orelse return error.FormatError;
    const password = iter.next() orelse return error.FormatError;

    return Line{
        .policy = try parsePasswordPolicy(policy),
        .password = password[1..],
    };
}

test "parseLine" {
    const line = "1-3 a: abcde";
    const parsed = try parseLine(line);

    try testing.expectEqualSlices(u8, parsed.password, "abcde");
    try testing.expectEqual(parsed.policy.min, 1);
    try testing.expectEqual(parsed.policy.max, 3);
    try testing.expectEqual(parsed.policy.char, 'a');
}

pub fn main() !void {
    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var valid_passwords: u32 = 0;

    const reader = file.reader();
    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const parsed = try parseLine(line);
        if (parsed.isValid()) valid_passwords += 1;
    }

    std.debug.print("valid passwords: {}\n", .{valid_passwords});
}
