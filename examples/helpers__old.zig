const std = @import("std");

fn generateFormatString(allocator: std.mem.Allocator, words: [][]const u8) ![]u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    for (words, 0..) |_, i| {
        try buffer.appendSlice("{s}");
        if (i != words.len - 1) {
            try buffer.append(',');
        }
    }

    return buffer.toOwnedSlice();
}

fn formatDynamic(buf: *std.ArrayList(u8), format: []const u8, args: [][]const u8) !void {
    var arg_index: usize = 0;
    var i: usize = 0;

    while (i < format.len) {
        if (i + 1 < format.len and format[i] == '{' and format[i + 1] == '}') {
            if (arg_index < args.len) {
                try buf.appendSlice(args[arg_index]);
                arg_index += 1;
            }
            i += 2;
        } else {
            try buf.append(format[i]);
            i += 1;
        }
    }
}

pub fn main() void {
    const allocator = std.heap.page_allocator;
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    const words = [_][]const u8{ "hello", "world", "foo", "bar", "baz" };

    const formatStr = generateFormatString(allocator, words) catch |err| {
        std.debug.print("error: {}\n", .{err});
        return;
    };
    defer allocator.free(formatStr);

    try formatDynamic(&buffer, formatStr, words);
    std.debug.print("{}\n", .{buffer.toSlice()});
}
