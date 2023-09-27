const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn toLowerCase(comptime size: usize, string: *const [size]u8) [size]u8 {
    var buffer: [size]u8 = undefined;
    for (string, 0..) |char, index| {
        buffer[index] = std.ascii.toLower(char);
    }
    return buffer;
}

pub fn extWithoutDotLowerCase(comptime size: usize, string: *const [size]u8, out: []u8) []const u8 {
    const ext = std.fs.path.extension(string);
    const ext2 = if (ext[0] == '.') ext[1..] else ext;
    const len = ext2.len;
    _ = std.ascii.lowerString(out[0..len], ext2[0..len]);
    return out[0..len];
}
