const std = @import("std");

const Commands = enum { echo, exit, type };
const CommandType = enum { builtin };

pub fn main() !u8 {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    while (true) {
        try stdout.print("$ ", .{});
        const user_input = try stdin.readUntilDelimiter(&buffer, '\n');
        var split_input = std.mem.splitScalar(u8, user_input, ' ');
        const first_word = split_input.next().?;
        const maybe_matched_cmd = std.meta.stringToEnum(Commands, first_word);
        if(maybe_matched_cmd) |matched_cmd| {
            switch (matched_cmd) {
                .echo => try cmd_echo(&split_input, stdout),
                .exit => return std.fmt.parseInt(u8, split_input.next() orelse "0", 10),
                .type => try cmd_type(&split_input, stdout)
            }
        } else {
            try stdout.print("{s}: command not found\n", .{user_input});
        }
    }
}

fn cmd_echo(args: *std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar), stdout: std.fs.File.Writer) !void {
    try stdout.print("{s}\n", .{args.rest()});
}

fn cmd_type(args: *std.mem.SplitIterator(u8, std.mem.DelimiterType.scalar), stdout: std.fs.File.Writer) !void {
    const maybe_cmd_to_type = args.next();
    if (maybe_cmd_to_type) |cmd_to_type| {
        const maybe_ct = std.meta.stringToEnum(Commands, cmd_to_type);
        if (maybe_ct) |_| {
            try stdout.print("{s} is a shell builtin\n", .{cmd_to_type});
        } else {
            try stdout.print("{s}: not found\n", .{cmd_to_type});
        }
    }
}

fn cmdtype(cmd: Commands) CommandType {
    switch(cmd) {
        .echo, .exit, .type => .builtin,
    }
}
