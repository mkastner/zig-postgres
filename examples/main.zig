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

    var db = try Pg.connect(allocator, build_options.db_uri);
    var result = try db.exec("SELECT schemaname, tablename FROM pg_tables WHERE NOT (schemaname LIKE 'pg_%' OR schemaname = 'information_schema')");
    //std.debug.print("Type of result: {*}\n", .{result.res});

    //std.debug.print("result {}         \n", .{result.res});
    //std.debug.print("result columns {?}\n", .{result.columns});
    std.debug.print("result rows    {?}\n", .{result.rows});

    //const analyzer_result = SchemaAnalyzer.inspect(db);
    //if (analyzer_result) |value| {
    //    std.debug.print("Success: {}\n", .{value});
    //} else |err| {
    //    std.debug.print("Could not perform schema inspection {}", err);
    //}

    defer {
        std.debug.assert(.ok == gpa.deinit());
        db.deinit();
    }

    //var result2 = try db.execValues("SELECT * FROM users WHERE id > {d};", .{20});

    //while (result2.parse(Users, allocator)) |value| {
    //    print("user: {s} \n", .{value.id});
    //}

    // _ = try db.exec("DROP TABLE users");
}
