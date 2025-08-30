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
        if (maybe_matched_cmd) |matched_cmd| {
            switch (matched_cmd) {
                .exit => return std.fmt.parseInt(u8, split_input.next() orelse "0", 10),
                .echo => try cmd_echo(&split_input, stdout),
                .type => try cmd_type(&split_input, stdout),
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
        var buffer: [10240]u8 = undefined;
        buffer[0] = 0; // start with a sentinel right at the beginning
        const maybe_ct = std.meta.stringToEnum(Commands, cmd_to_type);
        if (maybe_ct) |_| {
            try stdout.print("{s} is a shell builtin\n", .{cmd_to_type});
        } else {
            try search_path(&buffer, cmd_to_type);
            if (std.mem.len(@as([*c]u8, buffer[0..])) > 0) {
                try stdout.print("{s} is {s}\n", .{ cmd_to_type, buffer });
            } else {
                try stdout.print("{s}: not found\n", .{cmd_to_type});
            }
        }
    }
}

fn search_path(maybe_found_path: []u8, basename: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();
    const env_path = try std.process.getEnvVarOwned(alloc, "PATH");
    defer alloc.free(env_path);
    var found_path = false;

    var split_path = std.mem.splitScalar(u8, env_path, ':');
    while (split_path.next()) |dir| {
        //std.debug.print("trying path entry '{s}'\n", .{dir});
        const open_dir = std.fs.openDirAbsolute(dir, .{ .access_sub_paths = true, .iterate = true }) catch |err| {
            switch (err) {
                error.FileNotFound => {
                    //std.debug.print("path entry '{s}' does not exist\n", .{dir});
                    continue;
                },
                else => |leftover_err| return leftover_err,
            }
        };
        var walker = try open_dir.walk(alloc);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            //std.debug.print("checking '{s}' ", .{entry.basename});
            //std.debug.print(" {any}\n", .{entry.kind});
            if ((entry.kind == std.fs.Dir.Entry.Kind.file or entry.kind == std.fs.Dir.Entry.Kind.sym_link) and std.mem.eql(u8, entry.basename, basename)) {
                const file = try std.fs.Dir.openFile(entry.dir, entry.path, .{ .mode = .read_only });
                const perms = try file.mode();
                //std.debug.print("file mode: {s}\n", perms);
                if (perms & 0o1 == 1) {
                    std.mem.copyForwards(u8, maybe_found_path, dir);
                    std.mem.copyForwards(u8, maybe_found_path[dir.len..], "/");
                    std.mem.copyForwards(u8, maybe_found_path[dir.len + 1 ..], entry.path);
                    found_path = true;
                    break;
                }
            }
        }

        if (found_path) {
            break;
        }
    }
}
