const std = @import("std");
const vk = @import("vulkan");
const glfw = @import("glfw");

pub fn main() !void {

    var arena: std.heap.ArenaAllocator = .init(std.heap.smp_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    try glfw.init();
    defer glfw.terminate();

    if (glfw.vulkanSupported() != glfw.c.GLFW_TRUE){
        std.log.err("GLFW could not find vulkan", .{});
        return error.NoVulkan;
    }

    var extent = vk.Extent2D{ .width = 800, .height = 600 };

    glfw.windowHint(glfw.c.GLFW_CLIENT_API, glfw.c.GLFW_FALSE);
    var window = try glfw.Window.init(
        @as(i32, @intCast(extent.width)),
        @as(i32, @intCast(extent.height)),
        "Hello Vulkan",
        null,
        null
    );
    defer window.deinit();

    extent.width, extent.height = blk: {
        const size = window.getFramebufferSize();
        break :blk .{@intCast(size.w), @intCast(size.h)}; 
    };

    const VulkanLoader = struct {
        fn loadFn(instance: vk.Instance, name: [*:0]const u8) vk.PfnVoidFunction {
            const vk_instance: glfw.c.VkInstance = @ptrFromInt(@intFromEnum(instance));
            return @ptrCast(glfw.c.glfwGetInstanceProcAddress(vk_instance, name));
        }
    };


    var vkb = vk.BaseWrapper.load(VulkanLoader.loadFn);

    var extension_names: std.ArrayList([*:0]const u8) = .empty;

    var extension_count: u32 = 0;
    const required_extensions: [*c][*c]const u8 = glfw.getRequiredInstanceExtensions(&extension_count);
    try extension_names.appendSlice(allocator, @ptrCast(required_extensions[0..extension_count]));

    std.debug.print("Required Vulkan extensions : \n", .{});
    for(extension_names.items) |ext| {
        std.debug.print("{s}\n", .{ext});
    }

    const instance = try vkb.createInstance(&.{
        .p_application_info = &.{
            .p_application_name = "Hello Vulkan",
            .application_version = @bitCast(vk.makeApiVersion(0,0,0,0)),
            .p_engine_name = "Hello Vulkan",
            .engine_version = @bitCast(vk.makeApiVersion(0,0,0,0)),
            .api_version = @bitCast(vk.API_VERSION_1_2),
        },
        .flags = .{.enumerate_portability_bit_khr = true},
    }, null);

    _ = instance;

    while(!window.ShouldClose()){
        
        glfw.pollEvents();
        window.swapBuffers();
    }

}
