const std = @import("std");
const Postgres = @import("postgres");
const Definitions = @import("definitions");
const schema_utils = @import("schema_utils");
pub const c = @cImport({
    @cInclude("libpq-fe.h");
});

// queries
// all tables in database
// shop_development=# SELECT schemaname, tablename FROM pg_tables WHERE NOT (schemaname LIKE 'pg_%' OR schemaname = 'information_schema');

pub const DbField = struct {
    db_name: []const u8,
    field_name: []const u8,
    type: []const u8,
    //default_value: []const u8,
    pub fn print(self: *const DbField) !void {
        try std.json.stringify(self, .{}, std.io.getStdOut().writer());
    }
};

pub fn inspect(
    allocator: std.mem.Allocator,
    db: Postgres.Pg,
) !std.ArrayList(DbField) {
    const db_name_c = c.PQdb(db.connection);

    const db_name = @as([*c]const u8, db_name_c)[0..std.mem.len(db_name_c)];

    //const typeName = @typeName(db_name);
    std.debug.print("db_name is: {s}\n", .{db_name});

    const query_template = "SELECT table_schema, table_name, column_name, column_default  FROM information_schema.columns WHERE table_schema = '{s}'";

    var query_buffer: [512]u8 = undefined;
    const query = std.fmt.bufPrint(&query_buffer, query_template, .{db_name}) catch unreachable;

    std.debug.print("query : {s}\n", .{query});

    var result = db.rawExec(query) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return err;
    };

    // get number of columns and rows
    const rows = try schema_utils.getRowCount(result);
    std.debug.print("rows:    {}\n", .{rows});
    const cols = try schema_utils.getColumnCount(result);
    std.debug.print("cols:    {}\n", .{cols});

    var dbFields = std.ArrayList(DbField).init(allocator);

    var row_idx: usize = 0;
    while (row_idx < rows) : (row_idx += 1) {
        var col_idx: usize = 0;
        while (col_idx < cols) : (col_idx += 1) {
            const row_value = try schema_utils.getRowValue(result, row_idx, col_idx);
            //std.debug.print("{d} {s} \t", .{ col_idx, row_value });
            const dbField = DbField{ .db_name = db_name, .field_name = row_value, .type = row_value };
            _ = try dbField.print();
            dbFields.append(dbField) catch |err| {
                std.debug.print("Error: {}\n", .{err});
                return err;
            };
        }
        std.debug.print("\n", .{});
    }

    return dbFields;
}
