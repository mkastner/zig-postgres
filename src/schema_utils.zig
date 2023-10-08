const std = @import("std");
const Result = @import("Result").Result;
pub const c = @cImport({
    @cInclude("libpq-fe.h");
});

pub const Error = error{
    NullResult,
};

const ColumnType = @import("definitions").ColumnType;

pub fn getRowCount(result: ?*c.PGresult) !usize {
    if (result) |res| {
        return @as(usize, @intCast(c.PQntuples(res)));
    } else {
        return Error.NullResult;
    }
}

pub fn getColumnCount(result: ?*c.PGresult) !usize {
    if (result) |res| {
        return @as(usize, @intCast(c.PQnfields(res)));
    } else {
        return Error.NullResult;
    }
}

pub fn getColumnName(result: ?*c.PGresult, column_number: usize) ![]const u8 {
    if (result) |res| {
        const value = c.PQfname(res, @as(c_int, @intCast(column_number)));
        return @as([*c]const u8, value)[0..std.mem.len(value)];
    } else {
        return Error.NullResult;
    }
}

pub fn getColumnType(result: ?*c.PGresult, column_number: usize) !ColumnType {
    if (result) |res| {
        var oid = @as(usize, @intCast(c.PQftype(res, @as(c_int, @intCast(column_number)))));
        return std.meta.intToEnum(ColumnType, oid) catch return ColumnType.Unknown;
    } else {
        return Error.NullResult;
    }
}

pub fn getRowValue(result: ?*c.PGresult, row_number: usize, column_number: usize) ![]const u8 {
    if (result) |res| {
        const value = c.PQgetvalue(res, @as(c_int, @intCast(row_number)), @as(c_int, @intCast(column_number)));
        return @as([*c]const u8, value)[0..std.mem.len(value)];
    } else {
        return Error.NullResult;
    }
}
