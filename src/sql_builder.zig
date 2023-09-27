const std = @import("std");

const print = std.log.info;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const helpers = @import("helpers.zig");

const Definitions = @import("definitions.zig");
const Error = Definitions.Error;
const FieldInfo = @import("result.zig").FieldInfo;

pub const SQL = enum { Insert, Select, Delete, Update };

pub const Builder = struct {
    table_name: []const u8 = "",
    where_clause: ?[]const u8 = null,
    buffer: ArrayList(u8),
    columns: ArrayList([]const u8),
    values: ArrayList([]const u8),
    allocator: Allocator,
    build_type: SQL,

    pub fn new(build_type: SQL, allocator: Allocator) Builder {
        return Builder{
            .buffer = ArrayList(u8).init(allocator),
            .columns = ArrayList([]const u8).init(allocator),
            .values = ArrayList([]const u8).init(allocator),
            .allocator = allocator,
            .build_type = build_type,
        };
    }

    pub fn table(self: *Builder, table_name: []const u8) *Builder {
        self.table_name = table_name;
        return self;
    }

    pub fn where(self: *Builder, query: []const u8) *Builder {
        self.where_clause = query;
        return self;
    }

    pub fn addColumn(self: *Builder, column_name: []const u8) !void {
        try self.columns.append(column_name);
    }

    pub fn addIntValue(self: *Builder, value: anytype) !void {
        try self.values.append(try std.fmt.allocPrint(self.allocator, "{d}", .{value}));
    }

    pub fn addStringValue(self: *Builder, value: []const u8) !void {
        try self.values.append(try std.fmt.allocPrint(self.allocator, "'{s}'", .{value}));
    }

    pub fn addValue(self: *Builder, value: anytype) !void {
        switch (@TypeOf(value)) {
            u8, u16, u32, usize, i8, i16, i32 => {
                try self.addIntValue(value);
            },
            []const u8 => {
                try self.addStringValue(value);
            },
            else => {
                const int: ?u32 = std.fmt.parseInt(u32, value, 10) catch null;
                if (int != null) {
                    try self.addIntValue(int.?);
                } else {
                    try self.addStringValue(value);
                }
            },
        }
    }

    pub fn addStringArray(self: *Builder, values: [][]const u8) !void {
        _ = try self.buffer.writer().write("ARRAY[");
        for (values, 0..) |entry, i| _ = {
            _ = try self.buffer.writer().write(try std.fmt.allocPrint(self.allocator, "'{s}'", .{entry}));
            if (i < values.len - 1) _ = try self.buffer.writer().write(",");
        };
        _ = try self.buffer.writer().write("]");
        const s = try self.buffer.toOwnedSlice();
        try self.values.append(s);
    }

    pub fn addJson(self: *Builder, data: anytype) !void {
        _ = try self.buffer.writer().write("('");
        var buffer = std.ArrayList(u8).init(self.allocator);
        try std.json.stringify(data, .{}, buffer.writer());
        const s = try buffer.toOwnedSlice();
        _ = try self.buffer.writer().write(s);
        _ = try self.buffer.writer().write("')");
        const s2 = try self.buffer.toOwnedSlice();
        _ = try self.values.append(s2);
    }

    pub fn autoAdd(self: *Builder, struct_info: anytype, comptime field_info: FieldInfo, field_value: anytype, comptime extended: bool) !void {
        if (@typeInfo(field_info.type) == .Optional and field_value == null) return;
        switch (field_info.type) {
            i16, i32, u8, u16, u32, usize => {
                try self.addIntValue(field_value);
            },
            []const u8 => {
                try self.addStringValue(field_value);
            },
            ?[]const u8 => {
                try self.addStringValue(field_value.?);
            },
            else => {
                if (extended) try @field(struct_info, "onSave")(field_info, self, field_value);
            },
        }
    }

    pub fn end(self: *Builder) !void {
        switch (self.build_type) {
            .Insert => {
                _ = try self.buffer.writer().write("INSERT INTO ");
                _ = try self.buffer.writer().write(self.table_name);

                for (self.columns.items, 0..) |column, index| {
                    if (index == 0) _ = try self.buffer.writer().write(" (");
                    if (index == self.columns.items.len - 1) {
                        _ = try self.buffer.writer().write(column);
                        _ = try self.buffer.writer().write(") ");
                    } else {
                        _ = try self.buffer.writer().write(column);
                        _ = try self.buffer.writer().write(",");
                    }
                }
                _ = try self.buffer.writer().write("VALUES");

                for (self.values.items, 0..) |value, index| {
                    const columns_mod = index % self.columns.items.len;
                    const final_value = index == self.values.items.len - 1;

                    if (index == 0) _ = try self.buffer.writer().write(" (");
                    if (columns_mod == 0 and index != 0) {
                        _ = try self.buffer.writer().write(")");
                        _ = try self.buffer.writer().write(",");
                        _ = try self.buffer.writer().write("(");
                    }

                    _ = try self.buffer.writer().write(value);

                    if (!final_value and columns_mod != self.columns.items.len - 1) {
                        _ = try self.buffer.writer().write(",");
                    }

                    if (final_value) {
                        _ = try self.buffer.writer().write(")");
                        _ = try self.buffer.writer().write(";");
                    }
                }
            },
            .Update => {
                if (self.columns.items.len != self.values.items.len) {
                    std.log.warn("Columns and Values must match in length \n", .{});
                    return Error.QueryFailure;
                }

                if (self.where_clause == null) {
                    std.log.warn("Where clause must be set \n", .{});
                    return Error.QueryFailure;
                }

                _ = try self.buffer.writer().write("UPDATE ");
                _ = try self.buffer.writer().write(self.table_name);
                _ = try self.buffer.writer().write(" SET ");

                for (self.columns.items, 0..) |column, index| {
                    const final_value = index == self.columns.items.len - 1;

                    _ = try self.buffer.writer().write(column);
                    _ = try self.buffer.writer().write("=");
                    _ = try self.buffer.writer().write(self.values.items[index]);

                    if (!final_value) {
                        _ = try self.buffer.writer().write(",");
                    } else {
                        _ = try self.buffer.writer().write(" ");
                    }
                }

                _ = try self.buffer.writer().write(self.where_clause.?);
            },
            else => {
                return Error.NotImplemented;
            },
        }
    }

    pub fn command(self: *Builder) []const u8 {
        return self.buffer.items;
    }

    pub fn deinit(self: *Builder) void {
        if (self.where_clause != null) self.allocator.free(self.where_clause.?);

        self.columns.deinit();
        self.values.deinit();
        self.buffer.deinit();
    }

    //Build query string for executing in sql
    pub fn buildQuery(comptime query: []const u8, values: anytype, allocator: Allocator) ![]const u8 {
        comptime var values_info = @typeInfo(@TypeOf(values));
        comptime var temp_fields: [values_info.Struct.fields.len]std.builtin.Type.StructField = undefined;

        inline for (values_info.Struct.fields, 0..) |field, index| {
            switch (field.type) {
                i16, i32, u8, u16, u32, usize, comptime_int => {
                    temp_fields[index] = std.builtin.Type.StructField{
                        .name = field.name,
                        .type = i32,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = if (@sizeOf(field.type) > 0) @alignOf(field.type) else 0,
                    };
                },
                else => {
                    temp_fields[index] = std.builtin.Type.StructField{
                        .name = field.name,
                        .type = []const u8,
                        .default_value = null,
                        .is_comptime = false,
                        .alignment = if (@sizeOf(field.type) > 0) @alignOf(field.type) else 0,
                    };
                },
            }
        }
        values_info.Struct.fields = &temp_fields;

        var parsed_values: @Type(values_info) = undefined;

        inline for (std.meta.fields(@TypeOf(parsed_values))) |field| {
            const value = @field(values, field.name);

            switch (field.type) {
                comptime_int => {
                    @field(parsed_values, field.name) = @as(i32, @intCast(value));
                    return;
                },
                i16, i32, u8, u16, u32, usize => {
                    @field(parsed_values, field.name) = @as(i32, value);
                },
                else => {
                    @field(parsed_values, field.name) = try std.fmt.allocPrint(allocator, "'{s}'", .{value});
                },
            }
        }
        return try std.fmt.allocPrint(allocator, query, parsed_values);
    }
};

const testing = std.testing;

test "builder" {
    var builder = Builder.new(.Insert, testing.allocator).table("test");

    try builder.addColumn("id");
    try builder.addColumn("name");
    try builder.addColumn("age");

    try builder.addValue("5");
    try builder.addValue("Test");
    try builder.addValue("3");
    try builder.end();

    try testing.expectEqualStrings("INSERT INTO test (id,name,age) VALUES (5,'Test',3);", builder.command());

    builder.deinit();

    var builder2 = Builder.new(.Insert, testing.allocator).table("test");

    try builder2.addColumn("id");
    try builder2.addColumn("name");
    try builder2.addColumn("age");

    try builder2.addValue("5");
    try builder2.addValue("Test");
    try builder2.addValue("3");

    try builder2.addValue("1");
    try builder2.addValue("Test2");
    try builder2.addValue("53");

    try builder2.addValue("3");
    try builder2.addValue("Test3");
    try builder2.addValue("53");
    try builder2.end();

    try testing.expectEqualStrings("INSERT INTO test (id,name,age) VALUES (5,'Test',3),(1,'Test2',53),(3,'Test3',53);", builder2.command());
    builder2.deinit();

    var builder3 = Builder.new(.Update, testing.allocator).table("test").where(try Builder.buildQuery("WHERE NAME = {s};", .{"Steve"}, testing.allocator));

    try builder3.addColumn("id");
    try builder3.addColumn("name");
    try builder3.addColumn("age");

    try builder3.addValue("5");
    try builder3.addValue("Test");
    try builder3.addValue("3");

    try builder3.end();

    try testing.expectEqualStrings("UPDATE test SET id=5,name='Test',age=3 WHERE NAME = 'Steve';", builder3.command());
    builder3.deinit();
}
