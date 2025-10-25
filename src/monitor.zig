const std = @import("std");
const glfw = @import("c.zig").glfw;
const glfwError = @import("errors.zig").glfwError;

pub const Monitor = struct {
    const Self = @This();

    handle: ?*glfw.GLFWmonitor,

    pub fn init() glfwError!Self {
        const monitor_raw = glfw.glfwGetPrimaryMonitor();
        if (monitor_raw)|monitor|{
            return .{
                .handle = monitor
            };
        }
        else return glfwError.NoMonitorFound;
    }
};

test "Create The Monitor" {
    const root = @import("root.zig");
    try root.init();
    defer root.terminate();

    const monitor = Monitor.init() catch |err| {
        return err;
    };
    _ = monitor;
    try std.testing.expect(true);
}
