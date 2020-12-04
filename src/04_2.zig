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

const eye_colors = [_][]const u8{
    "amb", "blu", "brn", "gry", "grn", "hzl", "oth",
};

fn isValid(passport: BufMap) bool {
    const byr_raw = passport.get("byr") orelse return false;
    const byr = std.fmt.parseInt(u32, byr_raw, 10) catch return false;
    if (byr < 1920 or byr > 2002) return false;

    const iyr_raw = passport.get("iyr") orelse return false;
    const iyr = std.fmt.parseInt(u32, iyr_raw, 10) catch return false;
    if (iyr < 2010 or iyr > 2020) return false;

    const eyr_raw = passport.get("eyr") orelse return false;
    const eyr = std.fmt.parseInt(u32, eyr_raw, 10) catch return false;
    if (eyr < 2020 or eyr > 2030) return false;

    const hgt = passport.get("hgt") orelse return false;
    if (std.mem.endsWith(u8, hgt, "cm")) {
        const amt = std.fmt.parseInt(u32, hgt[0 .. hgt.len - 2], 10) catch return false;
        if (amt < 150 or amt > 193) return false;
    } else if (std.mem.endsWith(u8, hgt, "in")) {
        const amt = std.fmt.parseInt(u32, hgt[0 .. hgt.len - 2], 10) catch return false;
        if (amt < 59 or amt > 76) return false;
    } else return false;

    const hcl = passport.get("hcl") orelse return false;
    if (hcl.len != 7) return false;
    if (hcl[0] != '#') return false;
    for (hcl[1..]) |x| {
        const is_digit = x >= '0' and x <= '9';
        const is_a_to_f = x >= 'a' and x <= 'f';
        if (!is_digit and !is_a_to_f) return false;
    }

    const ecl = passport.get("ecl") orelse return false;
    for (eye_colors) |clr| {
        if (std.mem.eql(u8, clr, ecl)) break;
    } else return false;

    const pid = passport.get("pid") orelse return false;
    if (pid.len != 9) return false;
    for (pid[0..]) |x| {
        if (x < '0' or x > '9') return false;
    }

    return true;
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

test "not valid" {
    const allocator = std.testing.allocator;
    var passport = std.BufMap.init(allocator);
    defer passport.deinit();

    // eyr:1972 cid:100
    // hcl:#18171d ecl:amb hgt:170 pid:186cm iyr:2018 byr:1926
    try passport.set("eyr", "1972");
    try passport.set("cid", "100");
    try passport.set("hcl", "#18171d");
    try passport.set("ecl", "amb");
    try passport.set("hgt", "170");
    try passport.set("pid", "186cm");
    try passport.set("iyr", "2018");
    try passport.set("byr", "1926");

    testing.expect(!isValid(passport));
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
