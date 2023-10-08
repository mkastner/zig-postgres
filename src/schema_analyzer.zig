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

pub fn inspect(db: Postgres.Pg) !void {
    //const query = "SELECT schemaname, tablename  FROM pg_tables WHERE NOT (schemaname LIKE 'pg_%' OR schemaname = 'information_schema')";

    const db_name_c = c.PQdb(db.connection);

    const db_name = @as([*c]const u8, db_name_c)[0..std.mem.len(db_name_c)];

    //const typeName = @typeName(db_name);
    std.debug.print("db_name is: {s}\n", .{db_name});

    const query_template = "SELECT table_schema, table_name, column_name, column_default  FROM information_schema.columns WHERE table_schema = '{s}'";

    var query_buffer: [512]u8 = undefined;
    const query = std.fmt.bufPrint(&query_buffer, query_template, .{db_name}) catch unreachable;

    std.debug.print("query : {s}\n", .{query});
    //std.debug.print("query: {}\n", .{query});

    var result = db.rawExec(query) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return err;
    };

    // get number of columns and rows
    const rows = try schema_utils.getRowCount(result);
    std.debug.print("rows:    {}\n", .{rows});
    const cols = try schema_utils.getColumnCount(result);
    std.debug.print("cols:    {}\n", .{cols});

    var col_idx: usize = 0;
    while (col_idx < cols) : (col_idx += 1) {
        const col_name = try schema_utils.getColumnName(result, col_idx);
        //const col_type = try schema_utils.getColumnType(result, col_idx);
        std.debug.print("col_name: {s} \n", .{col_name});
        //std.debug.print("************* col_name: {s}\n", .{ col_name, col_type });
        var row_idx: usize = 0;
        while (row_idx < rows) : (row_idx += 1) {
            const value = try schema_utils.getRowValue(result, row_idx, col_idx);
            std.debug.print("{s} \t", .{value});
        }
        std.debug.print("\n", .{});
    }

    //const columns = schema_utils.getColumnCount(result);

    //std.debug.print("Main result rows:    {any}\n", .{rows});
    //std.debug.print("1 result columns: {}\n", .{columns});

    //std.debug.print("1 result columns: {}\n", .{result.columns});
    //std.debug.print("1 result rows:    {}\n", .{result.rows});

    //var col_idx: usize = 0;
    //while (col_idx < result.columns) : (col_idx += 1) {
    //    const col_name = try schema_utils.getColumnName(*result, col_idx);
    //    const col_type = try schema_utils.getColumnType(*result, col_idx);
    //    var row_idx: usize = 0;
    //    std.debug.print("result rows: {}\n", .{result.rows});
    //    while (row_idx < result.rows) : (row_idx += 1) {
    //        const value = try schema_utils.getColumnValue(*result, row_idx, col_idx);
    //        std.debug.print("col_name: {}, col_type: {}, value: {}\n", .{ col_name, col_type, value });
    //    }
    //}

}
