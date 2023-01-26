const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn toLowerCase(comptime size: usize, string: *const [size]u8) [size]u8 {
    var buffer: [size]u8 = undefined;
    for (string) |char, index| {
        buffer[index] = std.ascii.toLower(char);
    }
    return buffer;
}

pub fn extWithoutDot(comptime size: usize, string: *const [size]u8) []const u8 {
    const ext = std.fs.path.extension(string);
    const ext2 = if (ext[0] == '.') ext[1..] else ext;
    return ext2;
}

pub fn extWithoutDotLowerCase(comptime size: usize, string: *const [size]u8) []const u8 {
    const ext = std.fs.path.extension(string);
    const ext2 = if (ext[0] == '.') ext[1..] else ext;
    var buf: [256]u8 = undefined;
    const len = std.math.min(buf.len, ext2.len);
    return std.ascii.lowerString(buf[0..len], ext2[0..len]);
}
