const std = @import("std");
const builtin = @import("builtin");

const package_name = "postgres";
const package_path = "src/postgres.zig";

// const examples = [2][]const u8{ "main", "custom_types" };
const examples = [1][]const u8{"main"};

const Error = error{
    EnvironmentVariableNotFound,
};

//fn getEnvVar(allocator: std.mem.Allocator, env_name: []const u8) ![]u8 {
fn getEnvVar(allocator: std.mem.Allocator, env_name: []const u8) ![]const u8 {
    const env_map = try allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(allocator);
    //defer env_map.deinit();

    if (env_map.get(env_name)) |value| {
        return value;
    } else {
        return error.EnvironmentVariableNotFound;
    }
}

fn concat(allocator: std.mem.Allocator, str1: []const u8, str2: []const u8) ![]u8 {
    const result = try std.mem.join(allocator, ""[0..], &[_][]const u8{ str1, str2 });

    std.debug.print("Result: {s}\n", .{result});

    // Clean up the memory when done
    return result;
}

const include_dir = switch (builtin.target.os.tag) {
    .linux => "/usr/include",
    .windows => "C:\\Program Files\\PostgreSQL\\14\\include",
    //.macos => "/opt/homebrew/opt/libpq",
    .freebsd => "/usr/local/include",
    .macos => "/usr/local/opt/libpq",
    else => "/usr/include",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    b.addSearchPrefix(include_dir);

    const outer_definitions_module = b.addModule("definitions", .{ .source_file = .{ .path = "src/definitions.zig" } });

    _ = b.addModule(package_name, .{
        .source_file = .{ .path = package_path },
        .dependencies = &.{
            .{ .name = "definitions", .module = outer_definitions_module },
        },
    });

    const allocator = std.heap.page_allocator;

    const postgres_module = b.modules.get(package_name) orelse unreachable;
    const env = getEnvVar(allocator, "RUNTIME_ENV"[0..]) catch |err| {
        std.debug.print("Error getting environment variable: {}\n", .{err});
        return;
    };
    defer allocator.free(env);

    var buf: [1024]u8 = undefined;
    const capital_env = std.ascii.upperString(buf[0..], env);

    const host_env = concat(allocator, "DB_ZIGTEST_HOST_"[0..], capital_env[0..]) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };
    std.debug.print("host_env {s}\n", .{host_env});

    const database_env = concat(allocator, "DB_ZIGTEST_DATABASE_", capital_env) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };

    const user_env = concat(allocator, "DB_ZIGTEST_USER_", capital_env) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };

    // defer allocator.free(user);
    const password_env = concat(allocator, "DB_ZIGTEST_PASSWORD_", capital_env) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };
    // defer allocator.free(password);

    const host = getEnvVar(allocator, host_env[0..]) catch |err| {
        std.debug.print("Error getting environment variable: {}\n", .{err});
        return;
    };
    std.debug.print("host: {s}\n", .{host});

    const database = getEnvVar(allocator, database_env[0..]) catch |err| {
        std.debug.print("Error getting environment variable: {}\n", .{err});
        return;
    };
    std.debug.print("database: {s}\n", .{database});

    const user = getEnvVar(allocator, user_env[0..]) catch |err| {
        std.debug.print("Error getting environment variable: {}\n", .{err});
        return;
    };
    std.debug.print("user: {s}\n", .{user});

    const password = getEnvVar(allocator, password_env[0..]) catch |err| {
        std.debug.print("Error getting environment variable: {}\n", .{err});
        return;
    };
    std.debug.print("password: {s}\n", .{password});
    var uri_buf: [1024]u8 = undefined;
    const db_conn_uri = std.fmt.bufPrint(&uri_buf, "postgresql://{s}:{s}@{s}/{s}", .{ user, password, host, database }) catch |err| {
        std.debug.print("Error creating connection string: {}\n", .{err});
        return;
    };
    std.debug.print("db_conn_uri: {s}\n", .{db_conn_uri});

    const db_uri = b.option(
        []const u8,
        "db",
        "Specify the database url",
    ) orelse db_conn_uri; //"postgresql://{s}:{s}@{s}:5432/{s}";

    const db_options = b.addOptions();
    db_options.addOption([]const u8, "db_uri", db_uri);

    //const inner_definitions_module = b.addModule("definitions", .{ .source_file = .{ .path = "src/definitions.zig" } });
    const result_module = b.addModule("result", .{ .source_file = .{ .path = "src/result.zig" }, .dependencies = &.{
        .{ .name = "definitions", .module = outer_definitions_module },
    } });

    const schema_utils_module = b.addModule("schema_utils", .{ .source_file = .{ .path = "src/schema_utils.zig" }, .dependencies = &.{
        .{ .name = "result", .module = result_module },
        .{ .name = "definitions", .module = outer_definitions_module },
    } });

    const sql_builder_module = b.addModule("sql_builder", .{ .source_file = .{ .path = "src/sql_builder.zig" }, .dependencies = &.{
        .{ .name = "definitions", .module = outer_definitions_module },
    } });

    const helpers_module = b.addModule("helpers", .{ .source_file = .{ .path = "src/helpers.zig" }, .dependencies = &.{.{ .name = "definitions", .module = outer_definitions_module }} });

    const schema_analyzer_module = b.addModule("schema_analyzer", .{ .source_file = .{ .path = "src/schema_analyzer.zig" }, .dependencies = &.{
        .{ .name = "postgres", .module = postgres_module },
        .{ .name = "definitions", .module = outer_definitions_module },
        .{ .name = "schema_utils", .module = schema_utils_module },
    } });

    inline for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example,
            .root_source_file = .{ .path = "examples/" ++ example ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.addModule("postgres", postgres_module);

        exe.addModule("schema_analyzer", schema_analyzer_module);

        exe.addModule("result", result_module);

        exe.addModule("sql_builder", sql_builder_module);

        exe.addModule("helpers", helpers_module);

        //exe.addModule("definitions", inner_definitions_module);

        exe.addOptions("build_options", db_options);

        exe.linkSystemLibrary("pq");

        // depreacted
        //exe.install();
        // instead
        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(example, "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    const lib = b.addStaticLibrary(.{
        .name = package_name,
        .root_source_file = .{ .path = "src/postgres.zig" },
        .target = target,
        .optimize = optimize,
    });
    lib.addOptions("build_options", db_options);

    lib.linkSystemLibrary("pq");

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/database_tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.linkSystemLibrary("pq");
    tests.addModule("postgres", postgres_module);
    tests.addOptions("build_options", db_options);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);
}
