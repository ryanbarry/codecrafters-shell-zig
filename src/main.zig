const std = @import("std");

const Commands = enum { echo, exit, __unknown };

pub fn main() !u8 {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    while (true) {
        try stdout.print("$ ", .{});
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');
        var split_input = std.mem.splitScalar(u8, user_input, ' ');
        const first_word = split_input.next().?;
        const matched_cmd = std.meta.stringToEnum(Commands, first_word) orelse .__unknown;
        try switch (matched_cmd) {
            .echo => stdout.print("{s}\n", .{split_input.rest()}),
            .exit => return std.fmt.parseInt(u8, split_input.next().?, 10),
            .__unknown => stdout.print("{s}: command not found\n", .{user_input}),
        };
    }
}
