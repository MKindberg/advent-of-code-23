const std = @import("std");

pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    //
    // const optimize = b.standardOptimizeOption(.{});
    //
    // const exe = b.addExecutable(.{
    //     .name = "advent-of-code-23",
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    // b.installArtifact(exe);
    // const run_cmd = b.addRunArtifact(exe);
    // run_cmd.step.dependOn(b.getInstallStep());
    //
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }
    //
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);
    //
    // // Creates a step for unit testing. This only builds the test executable
    // // but does not run it.
    // const unit_tests = b.addTest(.{
    //     .root_source_file = .{ .path = "src/main.zig" },
    //     .target = target,
    //     .optimize = optimize,
    // });
    //
    // const run_unit_tests = b.addRunArtifact(unit_tests);
    //
    // // Similar to creating the run step earlier, this exposes a `test` step to
    // // the `zig build --help` menu, providing a way for the user to request
    // // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_unit_tests.step);

    const next_day = get_next_day(b);

    add_next_day_step(b, next_day);

    add_build_day_steps(b, next_day);
}

fn get_next_day(b: *std.Build) usize {
    var cwd = std.fs.cwd().openDir(".", .{}) catch return 0;
    defer cwd.close();
    for (1..26) |d| {
        cwd.access(b.fmt("day{}", .{d}), .{}) catch return d;
    }
    return 0;
}

fn add_next_day_step(b: *std.Build, next_day: usize) void {
    // Create dir
    var buf: [20]u8 = undefined;
    const new_dir_step = b.addSystemCommand(&.{ "mkdir", std.fmt.bufPrint(&buf, "day{}", .{next_day}) catch return });
    // Download input
    const download_step = b.addSystemCommand(&.{ "./download", std.fmt.bufPrint(&buf, "{}", .{next_day}) catch return });
    download_step.step.dependOn(&new_dir_step.step);
    // Add template
    const template_step = b.addSystemCommand(&.{ "cp", "template.zig", std.fmt.bufPrint(&buf, "day{}/main.zig", .{next_day}) catch return });
    template_step.step.dependOn(&new_dir_step.step);

    // Create target
    const new_step = b.step("new", "Create and prepare a dir for the next day");
    new_step.dependOn(&download_step.step);
    new_step.dependOn(&template_step.step);
}

fn add_build_day_steps(b: *std.Build, next_day: usize) void {
    if (next_day == 0) return;
    for (1..next_day) |d| {
        const day = std.fmt.allocPrint(b.allocator, "day{}", .{d}) catch unreachable;
        defer b.allocator.free(day);
        const main_file = std.fmt.allocPrint(b.allocator, "day{}/main.zig", .{d}) catch unreachable;
        defer b.allocator.free(main_file);
        const input_file = std.fmt.allocPrint(b.allocator, "day{}/input", .{d}) catch unreachable;
        defer b.allocator.free(input_file);

        const exe = b.addExecutable(.{
            .name = day,
            .root_source_file = .{ .path = main_file },
        });
        b.installArtifact(exe);
        b.installFile(input_file, "../input");
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        const run_step = b.step(day, "Run ");
        run_step.dependOn(&run_cmd.step);
    }
}
