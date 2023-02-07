const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const OptionsStep = std.build.OptionsStep;

const examples = [2][]const u8{ "main", "custom_types" };

const include_dir = switch (builtin.target.os.tag) {
    .linux => "/usr/include",
    .windows => "C:\\Program Files\\PostgreSQL\\14\\include",
    .macos => "/opt/homebrew/opt/libpq",
    else => "/usr/include",
};

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    b.addSearchPrefix(include_dir);
    const postgres_module = b.createModule(.{
        .source_file = .{ .path = "src/postgres.zig" },
    });

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
        exe.addOptions("build_options", db_options);
        exe.addModule("postgres", postgres_module);
        exe.linkSystemLibrary("pq");

        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(example, "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    const lib = b.addStaticLibrary(.{
        .name = "zig-postgres",
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
