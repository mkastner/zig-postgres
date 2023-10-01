const std = @import("std");
const Postgres = @import("postgres.zig");
const build_options = @import("build_options");

const Pg = Postgres.Pg;
const Result = Postgres.Result;
const Builder = Postgres.Builder;
const FieldInfo = Postgres.FieldInfo;
const Parser = Postgres.Parser;

const testing = std.testing;
const Allocator = std.mem.Allocator;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
pub const log_level: std.log.Level = .info;
pub fn printValue(value: []const u8) void {
    //std.debug.print("value {*}\n", .{value});
    std.log.info("value {*}\n", .{value});
}

test "database" {
    std.debug.print("****************** This is an info message", .{});
    var db = try Pg.connect(std.testing.allocator, build_options.db_uri);
    defer db.deinit();
    const schema =
        \\CREATE DATABASE zigtest; 
        \\CREATE TABLE IF NOT EXISTS users (id INT, name TEXT, age INT);
    ;
    std.debug.print("****************** This is an info message {*}", .{schema});

    printValue("test");

    _ = try db.exec(schema);

    _ = try db.execValues("SELECT * FROM users WHERE name = {s}", .{"Charlie"});
    _ = try db.execValues("SELECT * FROM users WHERE id = {d}", .{2});
    _ = try db.execValues("SELECT * FROM users WHERE age = {d}", .{25});
    var result4 = try db.execValues("SELECT * FROM users WHERE age = {d}", .{33});

    //When all results are not parsed, the memory must be manually deinited
    defer result4.deinit();

    //var user = result.parse(Users, null).?;

    //while (result3.parse(Users, allocator)) |res| testing.expectEqual(res.age, 25);

    try std.testing.expect(false);

    //SQL query builder

    //_ = try db.exec(builder.command());

}
