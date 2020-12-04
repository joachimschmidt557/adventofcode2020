const std = @import("std");
const Allocator = std.mem.Allocator;
const BufMap = std.BufMap;
const testing = std.testing;

const input_file = "input04.txt";

const fields = [_][]const u8{
    "byr",
    "iyr",
    "eyr",
    "hgt",
    "hcl",
    "ecl",
    "pid",
    "cid",
};

fn isValid(passport: BufMap) bool {
    return for (fields) |field| {
        if (std.mem.eql(u8, field, "cid")) continue;

        if (passport.get(field) == null) break false;
    } else true;
}

test "is valid" {
    const allocator = std.testing.allocator;
    var passport = std.BufMap.init(allocator);
    defer passport.deinit();

    // ecl:gry pid:860033327 eyr:2020 hcl:#fffffd
    // byr:1937 iyr:2017 cid:147 hgt:183cm
    try passport.set("ecl", "gry");
    try passport.set("pid", "860033327");
    try passport.set("eyr", "2020");
    try passport.set("hcl", "#fffffd");
    try passport.set("byr", "1937");
    try passport.set("iyr", "2017");
    try passport.set("cid", "147");
    try passport.set("hgt", "183cm");

    testing.expect(isValid(passport));
}

fn parsePassports(allocator: *Allocator, str: []const u8) ![]BufMap {
    var result = std.ArrayList(BufMap).init(allocator);

    var current_passport = BufMap.init(allocator);
    var iter = std.mem.split(str, "\n");
    while (iter.next()) |line| {
        if (line.len == 0) {
            try result.append(current_passport);
            current_passport = BufMap.init(allocator);
        } else {
            var item_iter = std.mem.split(line, " ");
            while (item_iter.next()) |item| {
                var part_iter = std.mem.split(item, ":");
                const key = part_iter.next() orelse return error.WrongFormat;
                const value = part_iter.next() orelse return error.WrongFormat;
                try current_passport.set(key, value);
            }
        }
    }

    return result.toOwnedSlice();
}

fn freePassports(allocator: *Allocator, passports: []BufMap) void {
    for (passports) |*x| x.deinit();
    allocator.free(passports);
}

test "parse passports" {
    const allocator = std.testing.allocator;
    const str =
        \\ecl:gry pid:860033327 eyr:2020 hcl:#fffffd
        \\byr:1937 iyr:2017 cid:147 hgt:183cm
        \\
        \\iyr:2013 ecl:amb cid:350 eyr:2023 pid:028048884
        \\hcl:#cfa07d byr:1929
        \\
        \\hcl:#ae17e1 iyr:2013
        \\eyr:2024
        \\ecl:brn pid:760753108 byr:1931
        \\hgt:179cm
        \\
        \\hcl:#cfa07d eyr:2025 pid:166559648
        \\iyr:2011 ecl:brn hgt:59in
        \\
    ;

    const parsed = try parsePassports(allocator, str);
    defer freePassports(allocator, parsed);

    testing.expectEqual(@as(usize, 4), parsed.len);
    testing.expectEqualSlices(u8, "gry", parsed[0].get("ecl").?);
    testing.expectEqualSlices(u8, "1931", parsed[2].get("byr").?);
    testing.expectEqual(@as(?[]const u8, null), parsed[0].get("asdf"));
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

    const passports = try parsePassports(allocator, content);
    defer freePassports(allocator, passports);

    var valid_passports: u32 = 0;
    for (passports) |p| {
        if (isValid(p)) valid_passports += 1;
    }

    std.debug.print("valid passports: {}\n", .{valid_passports});
}
