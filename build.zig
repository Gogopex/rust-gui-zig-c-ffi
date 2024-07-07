const std = @import("std");

fn setup_rust_gui(b: *std.Build, optimize: std.builtin.OptimizeMode) !std.Build.LazyPath {
    const tool_run = b.addSystemCommand(&.{"cargo"});
    tool_run.setCwd(b.path("src/gui/src"));
    tool_run.addArgs(&.{
        "build",
    });
    var opt_path: []const u8 = undefined;
    switch (optimize) {
        .ReleaseSafe,
        .ReleaseFast,
        .ReleaseSmall,
        => {
            tool_run.addArg("--release");
            opt_path = "release";
        },
        .Debug => {
            opt_path = "debug";
        },
    }

    const generated = try b.allocator.create(std.Build.GeneratedFile);
    generated.* = .{
        .step = &tool_run.step,
        .path = try b.build_root.join(b.allocator, &.{ "src/gui/target", opt_path, "libgui.a" }),
    };

    return .{ .generated = .{ .file = generated } };
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const opt = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "emerald",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = opt,
    });

    const libgui_path = try setup_rust_gui(b, opt);
    exe.addLibraryPath(libgui_path.dirname());
    exe.linkSystemLibrary("gui");

    exe.addIncludePath(b.path("src/gui"));

    // @TODO: condition these out if taget is not osx
    exe.linkFramework("CoreFoundation");
    exe.linkFramework("CoreGraphics");
    exe.linkFramework("Foundation");
    exe.linkFramework("AppKit");
    exe.linkFramework("CoreServices");
    exe.linkFramework("Carbon");
    exe.linkFramework("IOKit");
    exe.linkFramework("CoreVideo");
    exe.linkFramework("Metal");
    exe.linkFramework("QuartzCore");
    exe.linkFramework("OpenGL");

    exe.linkLibC();
    exe.linkLibCpp();
    b.installArtifact(exe);
}
