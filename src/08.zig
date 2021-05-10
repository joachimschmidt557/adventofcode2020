const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const input_file = "input08.txt";

const Op = enum(u8) {
    /// No Operation
    nop,
    /// Add signed 16-bit immediate to accumulator
    acc16,
    /// Jump by signed 16-bit immediate
    jmp16,
    _,

    pub fn len(self: Op) usize {
        return switch (self) {
            .nop => 1,
            .acc16, .jmp16 => 3,
            else => unreachable,
        };
    }
};

const CompileOptions = struct {
    ignore_jump_out_of_bounds: bool = false,
};

fn compile(allocator: *Allocator, reader: anytype, comptime opt: CompileOptions) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    errdefer result.deinit();

    var instruction_addr = std.AutoHashMap(usize, usize).init(allocator);
    defer instruction_addr.deinit();

    // First pass: assembly
    var instruction_counter: usize = 0;
    var buf: [1024]u8 = undefined;
    while (try reader.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var iter = std.mem.tokenize(line, " ");
        const op = iter.next() orelse return error.InvalidSyntax;

        try instruction_addr.put(instruction_counter, result.items.len);

        if (std.mem.eql(u8, "nop", op)) {
            try result.append(@enumToInt(Op.nop));
        } else if (std.mem.eql(u8, "acc", op)) {
            const arg = iter.next() orelse return error.ExpectedParameter;
            const imm = std.fmt.parseInt(i16, arg, 10) catch return error.InvalidIntegerLiteral;

            try result.append(@enumToInt(Op.acc16));
            std.mem.writeIntLittle(i16, try result.addManyAsArray(2), imm);
        } else if (std.mem.eql(u8, "jmp", op)) {
            const arg = iter.next() orelse return error.ExpectedParameter;
            const imm = std.fmt.parseInt(i16, arg, 10) catch return error.InvalidIntegerLiteral;

            try result.append(@enumToInt(Op.jmp16));
            std.mem.writeIntLittle(i16, try result.addManyAsArray(2), imm);
        } else return error.InvalidOp;

        instruction_counter += 1;
    }

    // Second pass: adjust jumps
    var i: usize = 0;
    instruction_counter = 0;
    while (i < result.items.len) {
        const op = @intToEnum(Op, result.items[i]);
        switch (op) {
            .jmp16 => {
                const offset = std.mem.readIntLittle(i16, result.items[i + 1 ..][0..2]);
                const location = @intCast(usize, @intCast(i16, instruction_counter) + offset);
                const code_location = instruction_addr.get(location) orelse if (opt.ignore_jump_out_of_bounds) 0 else return error.JumpOutOfBounds;
                const code_offset = @intCast(i16, code_location) - @intCast(i16, i);

                std.mem.writeIntLittle(i16, result.items[i + 1 ..][0..2], code_offset);
            },
            else => {},
        }

        i += op.len();
        instruction_counter += 1;
    }

    return result.toOwnedSlice();
}

test "bytecode compiler" {
    const allocator = std.testing.allocator;
    const assembly =
        \\nop +0
        \\acc +1
        \\jmp +1
        \\nop
        \\
    ;

    var fbs = std.io.fixedBufferStream(assembly);
    const reader = fbs.reader();
    const bytecode = try compile(allocator, reader, .{});
    defer allocator.free(bytecode);

    try testing.expectEqualSlices(u8, &[_]u8{
        0, // nop
        1, 1, 0, // acc +1
        2, 3, 0, // jmp +1
        0, // nop
    }, bytecode);
}

test "bytecode compiler bounds check" {
    const allocator = std.testing.allocator;
    const assembly =
        \\nop +0
        \\acc +1
        \\jmp +12
        \\nop
        \\
    ;

    var fbs = std.io.fixedBufferStream(assembly);
    const reader = fbs.reader();
    try testing.expectError(error.JumpOutOfBounds, compile(allocator, reader, .{}));
}

const Vm = struct {
    pc: usize = 0,
    accumulator: i32 = 0,
    bytecode: []const u8,
};

fn runUntilInfiniteLoop(allocator: *Allocator, vm: *Vm) !void {
    var visited_bytecode_addrs = std.AutoHashMap(usize, void).init(allocator);
    defer visited_bytecode_addrs.deinit();

    while (true) {
        if (visited_bytecode_addrs.get(vm.pc) != null) break;

        try visited_bytecode_addrs.put(vm.pc, {});
        const op = @intToEnum(Op, vm.bytecode[vm.pc]);
        switch (op) {
            .nop => {},
            .acc16 => {
                const imm = std.mem.readIntLittle(i16, vm.bytecode[vm.pc + 1 ..][0..2]);
                vm.accumulator += imm;
            },
            .jmp16 => {
                const imm = std.mem.readIntLittle(i16, vm.bytecode[vm.pc + 1 ..][0..2]);
                vm.pc = @intCast(usize, @intCast(isize, vm.pc) + imm);
            },
            else => unreachable,
        }

        switch (op) {
            .jmp16 => {},
            else => vm.pc += op.len(),
        }
    }
}

test "infinite loop detector" {
    const allocator = std.testing.allocator;
    const assembly =
        \\nop +0
        \\acc +1
        \\jmp +4
        \\acc +3
        \\jmp -3
        \\acc -99
        \\acc +1
        \\jmp -4
        \\acc +6
    ;

    var fbs = std.io.fixedBufferStream(assembly);
    const reader = fbs.reader();
    const bytecode = try compile(allocator, reader, .{});
    defer allocator.free(bytecode);

    var vm = Vm{ .bytecode = bytecode };
    try runUntilInfiniteLoop(allocator, &vm);
    try testing.expectEqual(@as(i32, 5), vm.accumulator);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = &gpa.allocator;

    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();
    const reader = file.reader();

    const bytecode = try compile(allocator, reader, .{ .ignore_jump_out_of_bounds = true });
    defer allocator.free(bytecode);

    var vm = Vm{ .bytecode = bytecode };
    try runUntilInfiniteLoop(allocator, &vm);

    std.debug.print("accumulator value before infinite loop: {}\n", .{vm.accumulator});
}
