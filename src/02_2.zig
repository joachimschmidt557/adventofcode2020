const std = @import("std");
const testing = std.testing;

const input_file = "input02.txt";

const PasswordPolicy = struct {
    pos_1: u32,
    pos_2: u32,
    char: u8,
};

fn parsePasswordPolicy(policy: []const u8) !PasswordPolicy {
    var iter = std.mem.split(policy, " ");
    const pos_1_pos_2 = iter.next() orelse return error.FormatError;
    const char = iter.next() orelse return error.FormatError;

    var iter_pos_1_pos_2 = std.mem.split(pos_1_pos_2, "-");
    const pos_1 = iter_pos_1_pos_2.next() orelse return error.FormatError;
    const pos_2 = iter_pos_1_pos_2.next() orelse return error.FormatError;

    return PasswordPolicy{
        .pos_1 = try std.fmt.parseInt(u32, pos_1, 10),
        .pos_2 = try std.fmt.parseInt(u32, pos_2, 10),
        .char = if (char.len == 1) char[0] else return error.CharacterTooLong,
    };
}

test "parsePasswordPolicy" {
    const policy = "1-3 a";
    const parsed = parsePasswordPolicy(policy);

    testing.expectEqual(parsed.pos_1, 1);
    testing.expectEqual(parsed.pos_2, 3);
    testing.expectEqual(parsed.char, 'a');
}

const Line = struct {
    policy: PasswordPolicy,
    password: []const u8,

    pub fn isValid(self: Line) bool {
        const pos_1_match = self.password[self.policy.pos_1 - 1] == self.policy.char;
        const pos_2_match = self.password[self.policy.pos_2 - 1] == self.policy.char;

        return pos_1_match != pos_2_match;
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
    const parsed = parseLine(line);

    testing.expectEqualSlices(u8, parsed.password, "abcde");
    testing.expectEqual(parsed.policy.pos_1, 1);
    testing.expectEqual(parsed.policy.pos_2, 3);
    testing.expectEqual(parsed.policy.char, 'a');
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
