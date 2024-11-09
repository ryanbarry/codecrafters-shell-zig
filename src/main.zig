const std = @import("std");

const Commands = enum { exit, __unknown };

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    while (true) {
        try stdout.print("$ ", .{});
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');
        const matched = std.meta.stringToEnum(Commands, user_input) orelse .__unknown;
        switch (matched) {
            .exit => break,
            .__unknown => try stdout.print("{s}: command not found\n", .{user_input}),
        }
    }
}
