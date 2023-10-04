const std = @import("std");
const Postgres = @import("postgres");
const Definitions = @import("definitions");

const Result = Postgres.Result;
// queries
// all tables in database
// shop_development=# SELECT schemaname, tablename FROM pg_tables WHERE NOT (schemaname LIKE 'pg_%' OR schemaname = 'information_schema');

pub const schema = {};

pub fn inspect(db: Postgres.Pg) !Result {
    //var result = try db.execValues("SELECT * FROM users WHERE name = {s};", .{""});
    var result = db.exec("SELECT schemaname, tablename FROM pg_tables WHERE NOT (schemaname LIKE 'pg_%' OR schemaname = 'information_schema')") catch |err| {
        //std.debug.print("Type of err: {}\n", .{@typeName(@TypeOf(err))});
        //std.debug.print("err {}\n", .{err.name});
        return err;
        //std.debug.print("Could not perform schema inspection {}", err);
    };
    return result;
}
