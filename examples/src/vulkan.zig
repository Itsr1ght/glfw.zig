const std = @import("std");
const vk = @import("vulkan");
const glfw = @import("glfw");

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    if (glfw.vulkanSupported() != glfw.c.GLFW_TRUE){
        std.log.err("GLFW could not find vulkan", .{});
        return error.NoVulkan;
    }
}
