const std = @import("std");

fn setup_rust_gui(b: *std.Build, optimize: std.builtin.OptimizeMode) !std.Build.LazyPath {
    const tool_run = b.addSystemCommand(&.{"cargo"});
    tool_run.setCwd(b.path("src/gui/rust"));
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
        .path = try b.build_root.join(b.allocator, &.{ "src/gui/rust/target", opt_path, "libgui.a" }),
    };

    const lib_path = std.Build.LazyPath{
        .generated = generated,
    };

    return lib_path;
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const opt = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "video-editor",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = opt,
    });

    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("GL");
    exe.linkSystemLibrary("avformat");
    exe.linkSystemLibrary("avcodec");
    exe.linkSystemLibrary("avutil");

    const libgui_path = try setup_rust_gui(b, opt);
    exe.addLibraryPath(libgui_path.dirname());
    exe.linkSystemLibrary("gui");

    exe.addCSourceFile(.{ .file = b.path("src/miniaudio_impl.c") });
    exe.addIncludePath(b.path("src/gui"));

    exe.linkLibC();
    exe.linkLibCpp();
    b.installArtifact(exe);
}
