const std = @import("std");
const Postgres = @import("postgres");
// queries
// all tables in database
// shop_development=# SELECT schemaname, tablename FROM pg_tables WHERE NOT (schemaname LIKE 'pg_%' OR schemaname = 'information_schema');

pub const schema = {};

pub fn inspect(pg: Postgres.Pg) void {
    _ = pg;
}
