const std = @import("std");
const print = std.debug.print;
const build_options = @import("build_options");

const SchemaAnalyzer = @import("schema_analyzer");
const Postgres = @import("postgres");
const Pg = Postgres.Pg;
const Result = Postgres.Result;
const Builder = Postgres.Builder;
const FieldInfo = Postgres.FieldInfo;

const ArrayList = std.ArrayList;
const Utf8View = std.unicode.Utf8View;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

const Users = struct {
    id: u16 = 0,
    name: []const u8 = "",
    age: u16 = 0,
};

pub fn main() !void {
    std.debug.print("\nRunning ...\n", .{});
    defer {
        if (gpa.deinit() != .ok) {
            std.debug.print("Error: Memory leaks detected.\n", .{});
        }
    }

    var db = try Pg.connect(allocator, build_options.db_uri);
    defer {
        db.deinit() catch |err| {
            std.debug.print("Error during db deinit: {}\n", .{err});
        };
    }

    const dbFields = try SchemaAnalyzer.inspect(allocator, db);
    defer dbFields.deinit();
    // Assert at the end, after other resources have been cleaned up
}
