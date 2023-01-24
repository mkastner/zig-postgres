const std = @import("std");
const builtin = @import("builtin");
const Builder = std.build.Builder;
const OptionsStep = std.build.OptionsStep;

const examples = [2][]const u8{ "main", "custom_types" };

const include_dir = switch (builtin.target.os.tag) {
    .linux => "/usr/include",
    .windows => "C:\\Program Files\\PostgreSQL\\14\\include",
    .macos => "/opt/homebrew/Cellar/libpq/15.1/include",
    else => "/usr/include",
};

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const db_uri = b.option(
        []const u8,
        "db",
        "Specify the database url",
    ) orelse "postgresql://postgres:postgres@localhost:5432";

    inline for (examples) |example| {
        const exe = b.addExecutable(example, "examples/" ++ example ++ ".zig");
        exe.setTarget(target);
        exe.setBuildMode(mode);
        const db_options = b.addOptions();
        exe.addOptions("db_options", db_options);
        db_options.addOption([]const u8, "db_uri", db_uri);

        exe.addIncludePath(include_dir);
        exe.addPackagePath("postgres", "src/postgres.zig");
        exe.linkSystemLibrary("c");
        exe.linkSystemLibrary("libpq");

        exe.install();

        const run_cmd = exe.run();
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(example, "Run the app");
        run_step.dependOn(&run_cmd.step);
    }

    const lib = b.addStaticLibrary("zig-postgres", "src/postgres.zig");
    lib.setTarget(target);
    lib.setBuildMode(mode);
    const db_options = b.addOptions();
    lib.addOptions("db_options", db_options);
    db_options.addOption([]const u8, "db_uri", db_uri);

    lib.addIncludePath(include_dir);
    lib.linkSystemLibrary("c");
    lib.linkSystemLibrary("libpq");

    const tests = b.addTest("tests.zig");
    tests.setBuildMode(mode);
    tests.setTarget(target);
    tests.addIncludePath(include_dir);
    tests.linkSystemLibrary("c");
    tests.linkSystemLibrary("libpq");
    tests.addPackagePath("postgres", "src/postgres.zig");
    tests.addOptions("db_options", db_options);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests.step);
}
