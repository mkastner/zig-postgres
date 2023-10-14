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

fn join(allocator: *std.mem.Allocator, slices: []const []const u8, separator: []const u8) !?[]const u8 {
    if (slices.len == 0) return null; // return null or empty slice based on your use case

    var total_length: usize = 0;
    for (slices) |slice| {
        total_length += slice.len;
    }
    total_length += separator.len * (slices.len - 1);

    var result = try allocator.alloc(u8, total_length);
    var offset: usize = 0;

    for (slices, 0..) |slice, i| {
        std.mem.copy(u8, result[offset..], slice);
        offset += slice.len;

        if (i != slices.len - 1) {
            std.mem.copy(u8, result[offset..], separator);
            offset += separator.len;
        }
    }

    return result;
}
