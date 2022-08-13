const testing = @import("std").testing;

test "tests" {
  testing.refAllDecls(@import("src/database_tests.zig"));
  testing.refAllDecls(@import("src/sql_builder.zig"));
}