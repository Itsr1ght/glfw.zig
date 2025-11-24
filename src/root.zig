const std = @import("std");

pub const Monitor = @import("monitor.zig").Monitor;
pub const Window = @import("window.zig").Window;

const glfw = @import("c.zig").glfw;

const glfwError = error {
    InitFailed,
    InitWindowError,
    NoMonitorFound
};

// global functions
pub const c = glfw;
pub fn init() glfwError!void {
    const result = glfw.glfwInit();
    if (result == 0) {
        return glfwError.InitFailed;
    }
}
pub const pollEvents = glfw.glfwPollEvents;
pub const terminate = glfw.glfwTerminate;
// opengl stuff
pub const GetProcAddress = glfw.glfwGetProcAddress;
// vulkan stuff
pub const vulkanSupported = glfw.glfwVulkanSupported;
pub const getRequiredInstanceExtensions = glfw.glfwGetRequiredInstanceExtensions;

// struct
test "Init GLFW" {
    init() catch |err| {
        return err;
    };
    defer terminate();
    try std.testing.expect(true);
}

test {
    std.testing.refAllDecls(@This());    
}
