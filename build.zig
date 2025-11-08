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
    const target_os = target.result.os.tag;

    switch (target_os) {
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


    const link_type_option = b.option(link_type, "link_type", "how does the glfw link with your executable") orelse default_link_type;
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
            compileGlfw(b, link_type_option, target_os);
        },
        .dynamic => {
            compileGlfw(b, link_type_option, target_os);
        }
    }

    glfw_mod.link_libc = true;


    const lib_unit_tests = b.addTest(.{
        .root_module = glfw_mod,
    });
    lib_unit_tests.linkLibC();
    lib_unit_tests.linkSystemLibrary("glfw");

    const run_unit_tests = b.addRunArtifact(lib_unit_tests);
    const run_test_step = b.step("test", "runs the unit tests");
    run_test_step.dependOn(&run_unit_tests.step);

    // example executables
    const opengl_exe = b.addExecutable(
        .{
            .name = "opengl",
            .root_module = b.createModule(
                .{
                    .root_source_file = b.path("examples/opengl.zig"),
                    .target = target,
                    .optimize = optimize
                }
            ),
        }
    );

    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.2",
        .profile = .core,
        .extensions = &.{ .ARB_clip_control, .NV_scissor_exclusive },
    });

    opengl_exe.root_module.addImport("gl", gl_bindings);

    const install_opengl_example = b.addInstallArtifact(opengl_exe, .{});

    opengl_exe.root_module.addImport("glfw", glfw_mod);
    const example_step = b.step("examples", "build all the example files");
    example_step.dependOn(&install_opengl_example.step);
}


fn compileGlfw(b: *std.Build, current_link_option: link_type, target: std.Target.Os.Tag) void {
    
    const glfw_package: *std.Build.Dependency= b.lazyDependency("glfw_c", .{}).?;
    const glfw_source_path: []const u8 = glfw_package.path("src").getPath(b);
    const c_flags: []const []const u8 = &.{"-02", "-std=c11"};

    const glfw_root_module = b.createModule(.{});

    const glfw_library = b.addLibrary(.{
        .linkage = switch(current_link_option) {
            .dynamic => .dynamic,
            else => .static
        },
        .name = "glfw",
        .root_module = glfw_root_module
    });
    
    // Common C Sources
    glfw_root_module.addCSourceFiles(.{
        .root = .{.cwd_relative = glfw_source_path},
        .language = .c,
        .flags = c_flags,
        .files = &.{
            "internal.h", "platform.h", "mappings.h", "context.c", "init.c", "input.c", "monitor.c", "platform.c",
            "vulkan.c", "window.c", "egl_context.c", "osmesa_context.c", "null_platform.h", "null_joystick.h", "null_init.c",
            "null_monitor.c", "null_window.c", "null_joystick.c"
        }
    });

    
    switch (target){
        // Apple C Sources
        .macos => {
            // Time, Thread C Source Files
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .flags = c_flags,
                .files = &.{
                    "cocoa_time.h", "cocoa_time.c", "posix_thread.h", "posix_module.c", "posix_thread.c"
                }
            });
            // Main Source Files
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .objective_c,
                .files = &.{
                    "cocoa_platform.h", "cocoa_joystick.h",
                    "cocoa_init.m", "cocoa_joystick.m", "cocoa_monitor.m",
                    "cocoa_window.m", "nsgl_context.m"
                },
            });
        },
        // Windows C Sources
        .windows => {
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .flags = c_flags,
                .files = &.{
                    "win32_time.h", "win32_thread.h", "win32_module.c", "win32_time.c", "win32_thread.c"
                }
            });
        },
        else => {
            glfw_root_module.addCSourceFiles(.{
                .root = .{.cwd_relative = glfw_source_path},
                .language = .c,
                .flags = c_flags,
                .files = &.{
                    "posix_time.h", "posix_thread.h", "posix_module.c", "posix_time.c", "posix_thread.c"
                }
            });
        },
    }
    std.posix.exit(0);
}
