// This file has been ported from GLFW's /src/CMakeLists.txt, made available under the zlib license (see ./LICENSE-GLFW.md)

const std = @import("std");

pub const PlatformFlags = struct {
    cocoa: bool,
    win32: bool,

    /// Following GLFW's build setup, `x11` and `wayland` can be built without `linux`.
    linux: bool,
    x11: bool,
    wayland: bool,
};

pub fn buildGlfw(b: *std.build.Builder, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode, platform: PlatformFlags) !*std.Build.Step.Compile {
    const libglfw = b.addStaticLibrary(.{
        .name = "glfw",
        .root_source_file = null,
        .target = target,
        .optimize = optimize,
    });

    libglfw.linkLibC();

    const GLFW_SRC_DIR = "deps/glfw/src/";

    libglfw.addCSourceFiles(&.{
        GLFW_SRC_DIR ++ "context.c",
        GLFW_SRC_DIR ++ "init.c",
        GLFW_SRC_DIR ++ "input.c",
        GLFW_SRC_DIR ++ "monitor.c",
        GLFW_SRC_DIR ++ "platform.c",
        GLFW_SRC_DIR ++ "vulkan.c",
        GLFW_SRC_DIR ++ "window.c",
        GLFW_SRC_DIR ++ "egl_context.c",
        GLFW_SRC_DIR ++ "osmesa_context.c",
        GLFW_SRC_DIR ++ "null_init.c",
        GLFW_SRC_DIR ++ "null_monitor.c",
        GLFW_SRC_DIR ++ "null_window.c",
        GLFW_SRC_DIR ++ "null_joystick.c",
    }, &.{});

    if (platform.cocoa) {
        libglfw.addCSourceFiles(&.{
            GLFW_SRC_DIR ++ "cocoa_time.c",
            GLFW_SRC_DIR ++ "posix_module.c",
            GLFW_SRC_DIR ++ "posix_thread.c",
        }, &.{});
    }

    if (platform.win32) {
        libglfw.addCSourceFiles(&.{
            GLFW_SRC_DIR ++ "win32_module.c",
            GLFW_SRC_DIR ++ "win32_time.c",
            GLFW_SRC_DIR ++ "win32_thread.c",
        }, &.{});
    }

    if (platform.linux) {
        libglfw.addCSourceFiles(&.{
            GLFW_SRC_DIR ++ "posix_module.c",
            GLFW_SRC_DIR ++ "posix_time.c",
            GLFW_SRC_DIR ++ "posix_thread.c",
        }, &.{});
    }

    if (platform.cocoa) {
        libglfw.defineCMacro("_GLFW_COCOA", null);
        libglfw.addCSourceFiles(&.{
            GLFW_SRC_DIR ++ "cocoa_init.m",
            GLFW_SRC_DIR ++ "cocoa_joystick.m",
            GLFW_SRC_DIR ++ "cocoa_monitor.m",
            GLFW_SRC_DIR ++ "cocoa_window.m",
            GLFW_SRC_DIR ++ "nsgl_context.m",
        }, &.{});
    }

    if (platform.win32) {
        libglfw.defineCMacro("_GLFW_WIN32", null);
        libglfw.addCSourceFiles(&.{
            GLFW_SRC_DIR ++ "win32_init.c",
            GLFW_SRC_DIR ++ "win32_joystick.c",
            GLFW_SRC_DIR ++ "win32_monitor.c",
            GLFW_SRC_DIR ++ "win32_window.c",
            GLFW_SRC_DIR ++ "wgl_context.c",
        }, &.{});
    }

    if (platform.x11) {
        libglfw.defineCMacro("_GLFW_X11", null);
        libglfw.addCSourceFiles(&.{
            GLFW_SRC_DIR ++ "x11_init.c",
            GLFW_SRC_DIR ++ "x11_monitor.c",
            GLFW_SRC_DIR ++ "x11_window.c",
            GLFW_SRC_DIR ++ "xkb_unicode.c",
            GLFW_SRC_DIR ++ "glx_context.c",
        }, &.{});
    }

    if (platform.wayland) {
        libglfw.defineCMacro("_GLFW_WAYLAND", null);
        libglfw.addCSourceFiles(&.{
            GLFW_SRC_DIR ++ "wl_init.c",
            GLFW_SRC_DIR ++ "wl_monitor.c",
            GLFW_SRC_DIR ++ "wl_window.c",
            GLFW_SRC_DIR ++ "xkb_unicode.c",
        }, &.{});
    }

    if (platform.x11 or platform.wayland) {
        if (platform.linux) {
            libglfw.addCSourceFiles(&.{
                GLFW_SRC_DIR ++ "linux_joystick.c",
            }, &.{});
        }
        libglfw.addCSourceFiles(&.{
            GLFW_SRC_DIR ++ "posix_poll.c",
        }, &.{});
    }

    if (platform.wayland) {
        // No detection logic for now.
        libglfw.defineCMacro("HAVE_MEMFD_CREATE", null);

        const wf = b.addWriteFiles();

        const WAYLAND_SCANNER = "wayland-scanner";

        var code: u8 = undefined;

        const wayland_client_pkgdatadir = try b.execAllowFail(&.{
            "pkg-config",
            "wayland-client",
            "--var=pkgdatadir",
        }, &code, .Ignore);

        const wayland_protocols_base = try b.execAllowFail(&.{
            "pkg-config",
            "wayland-protocols",
            "--var=pkgdatadir",
        }, &code, .Ignore);

        inline for (.{
            wayland_client_pkgdatadir,
            wayland_protocols_base,
            wayland_protocols_base,
            wayland_protocols_base,
            wayland_protocols_base,
            wayland_protocols_base,
            wayland_protocols_base,
        }, .{
            "/wayland.xml",
            "/stable/xdg-shell/xdg-shell.xml",
            "/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml",
            "/stable/viewporter/viewporter.xml",
            "/unstable/relative-pointer/relative-pointer-unstable-v1.xml",
            "/unstable/pointer-constraints/pointer-constraints-unstable-v1.xml",
            "/unstable/idle-inhibit/idle-inhibit-unstable-v1.xml",
        }, .{
            "wayland-client-protocol",
            "wayland-xdg-shell-client-protocol",
            "wayland-xdg-decoration-client-protocol",
            "wayland-viewporter-client-protocol",
            "wayland-relative-pointer-unstable-v1-client-protocol",
            "wayland-pointer-constraints-unstable-v1-client-protocol",
            "wayland-idle-inhibit-unstable-v1-client-protocol",
        }) |base, protocol_path, output_file| {
            const protocol = try std.mem.concat(
                b.allocator,
                u8,
                &.{
                    std.mem.trim(u8, base, " \r\n\t"),
                    protocol_path,
                },
            );
            const header = b.addSystemCommand(&.{ WAYLAND_SCANNER, "client-header", protocol });
            _ = wf.addCopyFile(
                header.addOutputFileArg(output_file ++ ".h"),
                output_file ++ ".h",
            );

            wf.step.dependOn(&header.step);

            const codeHeader = b.addSystemCommand(&.{ WAYLAND_SCANNER, "private-code", protocol });
            _ = wf.addCopyFile(
                codeHeader.addOutputFileArg(output_file ++ "-code.h"),
                output_file ++ "-code.h",
            );

            wf.step.dependOn(&codeHeader.step);
        }

        libglfw.addIncludePath(.{ .path = "a" });
        libglfw.addIncludePath(wf.getDirectory());
        libglfw.addIncludePath(.{ .path = "b" });

        libglfw.step.dependOn(&wf.step);
    }

    if (platform.cocoa) {
        libglfw.linkFrameworkNeeded("Cocoa");
        libglfw.linkFrameworkNeeded("IOKit");
        libglfw.linkFrameworkNeeded("CoreFoundation");
    }

    if (platform.win32) {
        libglfw.linkSystemLibrary("gdi32");
    }

    if (platform.x11) {
        libglfw.linkSystemLibrary("X11");
        libglfw.linkSystemLibrary("Xrandr");
        libglfw.linkSystemLibrary("Xinerama");
        // libglfw.linkSystemLibrary("Xkb");
        libglfw.linkSystemLibrary("Xcursor");
        libglfw.linkSystemLibrary("Xi");
        // libglfw.linkSystemLibrary("Xshape");
    }

    if (platform.wayland) {
        libglfw.linkSystemLibrary("wayland-client");
        libglfw.linkSystemLibrary("wayland-cursor");
        libglfw.linkSystemLibrary("wayland-egl");
        libglfw.linkSystemLibrary("xkbcommon");
    }

    return libglfw;
}
