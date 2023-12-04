const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "advent-of-code-23",
        .root_source_file = .{ .path = "src/main.zig" },
        .optimize = std.builtin.OptimizeMode.ReleaseFast,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run all days and measure runtime");
    run_step.dependOn(&run_cmd.step);

    const next_day = getNextDay(b);

    addNextDayStep(b, next_day);
    addTestDaySteps(b, next_day);
    const download_all_step = addDownloadAllStep(b, next_day).?;
    run_step.dependOn(download_all_step);
}

fn getNextDay(b: *std.Build) usize {
    var cwd = std.fs.cwd().openDir(".", .{}) catch return 0;
    defer cwd.close();
    for (1..26) |d| {
        cwd.access(b.fmt("src/day{}.zig", .{d}), .{}) catch return d;
    }
    return 0;
}

fn addNextDayStep(b: *std.Build, next_day: usize) void {
    // Download input
    const download_step = b.addSystemCommand(&.{ "./download", b.fmt("{}", .{next_day}) });
    // Add template
    const template_step = b.addSystemCommand(&.{ "cp", "template.zig", b.fmt("src/day{}.zig", .{next_day}) });
    // Create include file
    var includes = std.ArrayList(u8).init(b.allocator);
    defer includes.deinit();

    includes.appendSlice("pub const days = .{") catch unreachable;
    for (1..next_day + 1) |d| {
        includes.appendSlice("@import(\"day") catch unreachable;
        includes.append(@as(u8, @truncate(d)) + '0') catch unreachable;
        includes.appendSlice(".zig\"), ") catch unreachable;
    }
    includes.appendSlice("};\n") catch unreachable;
    const path = b.fmt("{s}/../src/days.zig", .{b.install_path});
    const include_step = b.addWriteFile(path, includes.items);
    // Dummy step to try avoid cacheing include_step
    include_step.step.dependOn(&b.addSystemCommand(&.{"touch", "src/days.zig"}).step);
    // Create target
    const new_step = b.step("new", "Create and prepare a dir for the next day");
    new_step.dependOn(&download_step.step);
    new_step.dependOn(&template_step.step);
    new_step.dependOn(&include_step.step);
}

fn addTestDaySteps(b: *std.Build, next_day: usize) void {
    if (next_day == 0) return;
    for (1..next_day) |d| {
        const num = b.fmt("{}", .{d});
        defer b.allocator.free(num);
        const day = b.fmt("day{}", .{d});
        defer b.allocator.free(day);
        const file = b.fmt("src/day{}.zig", .{d});
        defer b.allocator.free(file);

        const unit_tests = b.addTest(.{
            .root_source_file = .{ .path = file },
        });

        const run_unit_tests = b.addRunArtifact(unit_tests);

        const exe = b.addExecutable(.{
            .name = day,
            .root_source_file = .{ .path = file },
            .optimize = std.builtin.OptimizeMode.Debug,
        });
        const run_cmd = b.addRunArtifact(exe);

        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        const test_step = b.step(day, "Run this day");
        test_step.dependOn(&run_cmd.step);
        test_step.dependOn(&run_unit_tests.step);
        const test_step2 = b.step(num, "Run this day");
        test_step2.dependOn(&run_unit_tests.step);
        test_step2.dependOn(&run_cmd.step);
    }
}

fn addDownloadAllStep(b: *std.Build, next_day: usize) ?*std.Build.Step {
    if (next_day == 0) return null;

    var cwd = std.fs.cwd().openDir(".", .{}) catch unreachable;
    defer cwd.close();

    var buf: [20]u8 = undefined;
    _ = buf;
    const download_step = b.step("download_all", "Download all inputs");
    const create_dir = b.addSystemCommand(&.{
        "mkdir",
        "-p",
        "src/inputs",
    });
    for (1..next_day) |d| {
        cwd.access(b.fmt("src/inputs/day{}", .{d}), .{}) catch {
            const download_day = b.addSystemCommand(&.{ "./download", b.fmt("{}", .{d}) });
            download_day.step.dependOn(&create_dir.step);
            download_step.dependOn(&download_day.step);
        };
    }
    return download_step;
}
