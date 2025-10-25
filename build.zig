const std = @import("std");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw_mod = b.addModule(
        "glfw",
        .{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }
    );

    glfw_mod.link_libc = true;
    glfw_mod.linkSystemLibrary("glfw", .{});

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
