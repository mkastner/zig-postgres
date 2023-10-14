const std = @import("std");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

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
    const result = buf.toOwnedSlice() catch |err| {
        std.debug.print("error: {}\n", .{err});
        return;
    };
    _ = std.fmt.bufPrint(result, "\n", .{}) catch |err| {
        std.debug.print("error: {}\n", .{err});
        return;
    };
}

pub fn main() void {
    const allocator = gpa.allocator();
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    var words = [_][]const u8{ "hello", "world", "foo", "bar", "baz" };

    const formatStr = generateFormatString(allocator, &words) catch |err| {
        std.debug.print("error: {}\n", .{err});
        return;
    };
    defer allocator.free(formatStr);
    std.debug.print("\nformatStr {s}\n", .{formatStr});

    formatDynamic(&buffer, formatStr, &words) catch |err| {
        std.debug.print("error: {}\n", .{err});
        return;
    };
    const result = buffer.toOwnedSlice() catch |err| {
        std.debug.print("error: {}\n", .{err});
        return;
    };
    std.debug.print("result {s}\n", .{result});
}
