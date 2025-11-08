const std = @import("std");


const link_type = enum {
    static,
    dynamic,
    system
};


pub fn build(b: *std.Build) void {


    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var default_link_type: link_type = .static;

    switch (target.result.os.tag) {
        .linux, .macos => {
            default_link_type = .system;
        },
        .windows => {
            default_link_type = .dynamic;
        },
        else => {
            std.debug.panic("Unsupported OS", .{});
        }
    }


    const link_type_option = b.option(
        link_type, "link_type", "how does the glfw link with your executable"
    ) orelse default_link_type;
    
    const glfw_mod = b.addModule(
        "glfw",
        .{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }
    );

    glfw_mod.link_libc = true;
    switch (link_type_option){
        .system => {
            glfw_mod.linkSystemLibrary("glfw", .{});
        },
        .static => {
            const glfw_library: *std.Build.Step.Compile = compileGlfw(b, link_type_option, target, optimize);
            glfw_mod.linkLibrary(glfw_library);
        },
        .dynamic => {
            const glfw_library: *std.Build.Step.Compile = compileGlfw(b, link_type_option, target, optimize);
            b.installArtifact(glfw_library);
            glfw_mod.linkLibrary(glfw_library);
        }
    }

    glfw_mod.link_libc = true;


    const lib_unit_tests = b.addTest(.{
        .root_module = glfw_mod,
    });

    lib_unit_tests.linkLibC();

    const run_unit_tests = b.addRunArtifact(lib_unit_tests);
    const run_test_step = b.step("test", "runs the unit tests");
    run_test_step.dependOn(&run_unit_tests.step);
}


fn compileGlfw(
    b: *std.Build, current_link_option: link_type,
    target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode
    ) *std.Build.Step.Compile {
    
    const glfw_package: *std.Build.Dependency= b.lazyDependency("glfw_c", .{}).?;
    const glfw_source_path: []const u8 = glfw_package.path("src").getPath(b);
    const glfw_include_path: []const u8 = glfw_package.path("include/GLFW").getPath(b);

    const glfw_root_module = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });

    const glfw_library = b.addLibrary(.{
        .linkage = switch(current_link_option) {
            .dynamic => .dynamic,
            else => .static
        },
        .name = "glfw",
        .root_module = glfw_root_module,
    });

    glfw_root_module.link_libc = true;
    if (current_link_option == .dynamic) {
        glfw_root_module.addCMacro("_GLFW_BUILD_DLL", "1");
    }
    
    glfw_root_module.addIncludePath(.{
        .cwd_relative = glfw_include_path
    }); 
    glfw_root_module.addIncludePath(.{
        .cwd_relative = glfw_source_path
    }); 

    // Common C Sources
    glfw_root_module.addCSourceFiles(.{
        .root = .{.cwd_relative = glfw_source_path},
        .language = .c,
        .files = &.{
            "context.c", "init.c", "input.c", "monitor.c", "platform.c",
            "vulkan.c", "window.c", "egl_context.c","osmesa_context.c", "null_init.c",
            "null_monitor.c", "null_window.c", "null_joystick.c"
        }
    });

    switch (target.result.os.tag){
        // Apple C Sources
        .macos => {
            glfw_root_module.addCMacro("_GLFW_COCOA", "1");

            // Time, Thread C Source Files (MacOS specific)
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .files = &.{
                    "cocoa_time.c", "posix_module.c", "posix_thread.c"
                }
            });

            // Main Source Files
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .objective_c,
                .files = &.{
                    "cocoa_init.m", "cocoa_joystick.m", "cocoa_monitor.m",
                    "cocoa_window.m", "nsgl_context.m"
                },
            });
            glfw_root_module.linkFramework("Cocoa", .{});
            glfw_root_module.linkFramework("IOKit", .{});
            glfw_root_module.linkFramework("CoreFoundation", .{});
            glfw_root_module.linkFramework("QuartzCore", .{});
        },
        // Windows C Sources
        .windows => {
            glfw_root_module.addCMacro("_GLFW_WIN32", "1");

            // Time, Thread C Source Files (Widows specific)
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .files = &.{
                    "win32_module.c", "win32_time.c", "win32_thread.c"
                }
            });

            // Main Source Files
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .files = &.{
                    "win32_init.c", "win32_joystick.c", "win32_monitor.c",
                    "win32_window.c", "wgl_context.c"
                }
            });
            
            glfw_root_module.linkSystemLibrary("user32", .{});
            glfw_root_module.linkSystemLibrary("gdi32", .{});
            glfw_root_module.linkSystemLibrary("kernel32", .{});
            glfw_root_module.linkSystemLibrary("shell32", .{});
        },
        else => {

            glfw_root_module.addCMacro("_GLFW_X11", "1");

            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .files = &.{
                    "posix_module.c", "posix_time.c", "posix_thread.c"
                }
            });

            // Main Source Files

            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .files = &.{
                    "x11_init.c", "x11_monitor.c", "x11_window.c", "xkb_unicode.c", "glx_context.c"
                }
            });

            // For X11 
            // For Testing purpose i only use x11
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .files = &.{
                    "x11_init.c", "x11_monitor.c", "x11_window.c", "xkb_unicode.c", "glx_context.c", "linux_joystick.c", "posix_poll.c"
                }
            });

        },
    }
    return glfw_library;
}
