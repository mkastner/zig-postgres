const std = @import("std");
const builtin = @import("builtin");

const package_name = "postgres";
const package_path = "src/postgres.zig";

const examples = [2][]const u8{ "main", "custom_types" };

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

    _ =
        b.addModule("definitions", .{ .source_file = .{ .path = "definitions.zig" } });

    // Export zig-postgres as a module
    _ = b.addModule(package_name, .{ .source_file = .{ .path = package_path } });

    //exe.addModule("definitions", definitions_module);

    const postgres_module = b.modules.get(package_name) orelse unreachable;

    const db_uri = b.option(
        []const u8,
        "db",
        "Specify the database url",
    ) orelse "postgresql://postgresql:postgresql@localhost:5432/mydb";

    const db_options = b.addOptions();
    db_options.addOption([]const u8, "db_uri", db_uri);

    inline for (examples) |example| {
        const exe = b.addExecutable(.{
            .name = example,
            .root_source_file = .{ .path = "examples/" ++ example ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });

        const result_module = b.addModule("result", .{ .source_file = .{ .path = "result.zig" } });
        exe.addModule("result", result_module);

        const sql_builder_module = b.addModule("sql_builder", .{ .source_file = .{ .path = "sql_builder.zig" } });
        exe.addModule("sql_builder", sql_builder_module);

        const helpers_module = b.addModule("helpers", .{ .source_file = .{ .path = "helpers.zig" } });
        exe.addModule("helpers", helpers_module);

        const inner_definitions_module = b.addModule("definitions", .{ .source_file = .{ .path = "definitions.zig" } });
        exe.addModule("definitions", inner_definitions_module);

        exe.addOptions("build_options", db_options);
        // exe.addModule("postgres", postgres_module);
        exe.addModule("postgres", postgres_module);

        exe.linkSystemLibrary("pq");

        // depreacted
        //exe.install();
        // instead
        b.installArtifact(exe);

        //const run_cmd = exe.run();
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
        .root_source_file = .{ .path = "tests.zig" },
        .target = target,
        .optimize = optimize,
    });
    tests.linkSystemLibrary("pq");
    tests.addModule("postgres", postgres_module);
    tests.addOptions("build_options", db_options);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);
}
