const std = @import("std");

pub fn build(b: *std.Build) void {
    
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});


// 
// OPENGL EXAMPLE
//

    const opengl_exe = b.addExecutable(
        .{
            .name = "opengl",
            .root_module = b.createModule(
                .{
                    .root_source_file = b.path("src/opengl.zig"),
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

    const glfw_package_opengl = b.dependency("glfw", .{
        .target = target,
        .optimize = optimize,
        .link_type = .static
    });

    opengl_exe.root_module.addImport("gl", gl_bindings);
    opengl_exe.root_module.addImport("glfw", glfw_package_opengl.module("glfw"));

// 
// VULKAN EXAMPLE
//

    const vulkan_exe = b.addExecutable(.{
        .name = "vulkan",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/vulkan.zig"),
            .target = target,
            .optimize = optimize
        })
    });

    const glfw_package_vulkan = b.dependency("glfw", .{
        .target = target,
        .optimize = optimize,
        .link_type = .static,
        .vulkan_support = true,
    });

    const vulkan = b.dependency("vulkan", .{
        .registry = b.dependency("vulkan_headers", .{}).path("registry/vk.xml"),
    }).module("vulkan-zig");
    
    vulkan_exe.root_module.addImport("vulkan", vulkan);
    vulkan_exe.root_module.addImport("glfw", glfw_package_vulkan.module("glfw"));

    const install_opengl_example = b.addInstallArtifact(opengl_exe, .{});
    const install_vulkan_example = b.addInstallArtifact(vulkan_exe, .{});
    const example_step = b.step("examples", "build all the example files");
    example_step.dependOn(&install_opengl_example.step);
    example_step.dependOn(&install_vulkan_example.step);

    if(glfw_package_opengl.builder.user_input_options.get("link_type")) |link_type|{
        if(std.mem.eql(u8, link_type.value.scalar, "dynamic")){
            opengl_exe.linkLibrary(glfw_package_opengl.artifact("glfw"));
            const glfw_artifact = glfw_package_opengl.artifact("glfw");
            const install_glfw_artifact = b.addInstallArtifact(glfw_artifact,
                .{.dest_dir = .{.override = .bin}}
            );
            example_step.dependOn(&install_glfw_artifact.step);
        }
    }
    if(glfw_package_vulkan.builder.user_input_options.get("link_type")) |link_type|{
        if(std.mem.eql(u8, link_type.value.scalar, "dynamic")){
            vulkan_exe.linkLibrary(glfw_package_vulkan.artifact("glfw"));
            const glfw_artifact = glfw_package_vulkan.artifact("glfw");
            const install_glfw_artifact = b.addInstallArtifact(glfw_artifact,
                .{.dest_dir = .{.override = .bin}}
            );
            example_step.dependOn(&install_glfw_artifact.step);
        }
    }
}
