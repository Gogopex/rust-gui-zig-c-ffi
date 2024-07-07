const std = @import("std");

fn setup_rust_gui(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) !std.Build.LazyPath {
    const tool_run = b.addSystemCommand(&.{"cargo"});
    tool_run.setCwd(b.path("src/gui"));
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

    // Add target-specific arguments
    if (target.result.os.tag == .macos) {
        tool_run.addArgs(&.{ "--target", "aarch64-apple-darwin" });
    } else {
        @panic("Unsupported target");
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

    const libgui_path = try setup_rust_gui(b, target, opt);
    exe.addObjectFile(libgui_path);
    exe.addIncludePath(b.path("src/gui"));

    // Add frameworks and libraries
    const frameworks = [_][]const u8{
        "ApplicationServices", "CoreFoundation", "CoreVideo",  "CoreText",   "Security",
        "CoreGraphics",        "AppKit",         "QuartzCore", "Foundation", "IOSurface",
        "CoreMedia",           "VideoToolbox",   "Metal",
    };
    for (frameworks) |framework| {
        exe.linkFramework(framework);
    }

    exe.linkSystemLibrary("System");
    exe.linkSystemLibrary("objc");
    exe.linkSystemLibrary("curl");
    exe.linkSystemLibrary("iconv");
    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");

    exe.linkLibC();
    exe.linkLibCpp();

    // yolo linker flags
    exe.addLibraryPath(.{ .cwd_relative = "/usr/lib" });
    exe.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    exe.addIncludePath(.{ .cwd_relative = "/usr/include" });
    exe.addIncludePath(.{ .cwd_relative = "/usr/local/include" });

    // trying to make sure all symbols are exported
    exe.linkage = .dynamic;
    exe.bundle_compiler_rt = true;
    exe.want_lto = false;

    b.installArtifact(exe);
}
