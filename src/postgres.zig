const std = @import("std");
pub const c = @cImport({
    @cInclude("libpq-fe.h");
});

const build_options = @import("build_options");

pub const Builder = @import("sql_builder.zig").Builder;
pub const Parser = @import("parser");

const helpers = @import("helpers.zig");
const Definitions = @import("definitions");
const Error = Definitions.Error;

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

//pub const Result = @import("result.zig").Result;
pub const FieldInfo = @import("result.zig").FieldInfo;

const print = std.debug.print;

pub const Pg = struct {
    const Self = @This();

    connection: *c.PGconn,
    allocator: std.mem.Allocator,

    pub fn connect(allocator: std.mem.Allocator, address: []const u8) !Self {
        //var conn_info = try std.cstr.addNullByte(allocator, address);
        var conn_info = try allocator.dupeZ(u8, address);
        var connection: *c.PGconn = undefined;

        defer allocator.free(conn_info);

        if (c.PQconnectdb(conn_info)) |conn| {
            connection = conn;
        }

        if (c.PQstatus(connection) != c.CONNECTION_OK) {
            return Error.ConnectionFailure;
        }

        return Self{
            .allocator = allocator,
            .connection = connection,
        };
    }

    pub fn rawExec(self: Self, query: []const u8) !?*c.PGresult {
        //var cstr_query = try std.cstr.addNullByte(self.allocator, query);
        var cstr_query = try self.allocator.dupeZ(u8, query);
        defer self.allocator.free(cstr_query);

        var pgRes: ?*c.PGresult = c.PQexec(self.connection, cstr_query);
        // var response_code = @enumToInt(c.PQresultStatus(res));
        var response_code = c.PQresultStatus(pgRes);

        if (response_code != c.PGRES_TUPLES_OK and response_code != c.PGRES_COMMAND_OK and response_code != c.PGRES_NONFATAL_ERROR) {
            //std.debug.print("Error {s}\n", .{c.PQresultErrorMessage(pgRes)});
            c.PQclear(pgRes);
            return Error.QueryFailure;
        }
        //std.debug.print("response_code {}\n", .{response_code});
        //std.debug.print("pgRes           {?}\n", .{pgRes});

        if (pgRes) |pgResult| {
            return pgResult;
        } else {
            return Error.QueryFailure;
        }
    }

    pub fn deinit(self: *Self) void {
        c.PQfinish(self.connection);
    }
};
