const std = @import("std");
const glfw = @import("c.zig").glfw;
const glfwError = @import("errors.zig").glfwError;
const Monitor = @import("monitor.zig").Monitor;


pub const Window = struct {
    const Self = @This();

    handle: ?*glfw.GLFWwindow,
    monitor: ?Monitor,
    share: ?*Self,


    pub fn init(width: i32, height: i32, title: [*]const u8, monitor: ?Monitor, share: ?*Self) glfwError!Self {
        const monitor_pointer = if (monitor)|m| m.handle else null;
        const share_pointer = if (share)|s| s.handle else null;
        const raw_handle = glfw.glfwCreateWindow(
            @as(i32, @intCast(width)),
            @as(i32, @intCast(height)), 
            title, monitor_pointer, share_pointer);
        if (raw_handle) |handle|{
            return .{
                .handle = handle,
                .monitor = monitor,
                .share = share
            };
        }
        else return glfwError.InitWindowError;
    }

    pub fn setWindowResize(self: Self, width: i32, height: i32) void {
        glfw.glfwSetWindowSize(self.handle, width, height);
    }

    pub fn getWindowSize(self: Self) struct {u32, u32} {
        var width = 0;var height = 0;
        glfw.glfwGetWindowSize(self.handle, &width, &height);
        return .{width, height};
    }

    pub fn setKeyCallback(self: *Self, callback_func: fn(window: ?*glfw.GLFWwindow, key: c_int, scancode: c_int, action: c_int, mods: c_int) callconv(.c) void) void {
        _ = glfw.glfwSetKeyCallback(self.handle, callback_func);
    }

    pub fn setFramebufferSizeCallback(self: *Self, callback_func: fn(window: ?*glfw.GLFWwindow, width: c_int, height: c_int) callconv(.c) void) void {
        _ = glfw.glfwSetWindowSizeCallback(self.handle, callback_func);
    }

    pub fn setWindowTitle(self: Self, new_title: [*]const u8) void {
        glfw.glfwSetWindowTitle(self.handle, new_title);
    }

    pub fn deinit(self: Self) void {
       glfw.glfwDestroyWindow(self.handle);
    }

    pub fn getFramebufferSize(self: *Self) struct {w: c_int, h: c_int} {
        var w: c_int = undefined;
        var h: c_int = undefined;
        glfw.glfwGetFramebufferSize(self.handle, &w, &h);
        return .{ .w = w, .h = h };
    }

    pub fn makeContextCurrent(self: Self) void {
        glfw.glfwMakeContextCurrent(self.handle);
    }

    pub fn swapBuffers(self: Self) void {
        glfw.glfwSwapBuffers(self.handle);
    }

    pub fn ShouldClose(self: Self) bool {
        return if (glfw.glfwWindowShouldClose(self.handle) == 0) false else true;
    }
};


test "create the window" {
    const root = @import("root.zig");
    try root.init();
    defer root.terminate();
    
    const window = Window.init(200, 200, "Test Window", null, null) catch |err| {
        return err;
    };
    defer window.deinit();
    try std.testing.expect(true);
}

test "window should close needs to be false" {
    const root = @import("root.zig");
    try root.init();
    defer root.terminate();

    const window = try Window.init(200, 200, "Test Window", null, null);
    try std.testing.expectEqual(false, window.ShouldClose());
}
