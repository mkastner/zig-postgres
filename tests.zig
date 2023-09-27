const testing = @import("std").testing;
const imported_database_tests = @import("src/database_tests.zig");
//const sql_builder = @import("src/sql_builder.zig");

test "tests" {
    _ = imported_database_tests;
    //testing.refAllDecls(@This());
    //_ = @import("src/sql_builder.zig");
}
