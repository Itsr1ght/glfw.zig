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

    pub fn deinit(self: Self) void {
       glfw.glfwDestroyWindow(self.handle);
    }

    pub fn makeContextCurrent(self: Self) void {
        glfw.glfwMakeContextCurrent(self.handle);
    }

    pub fn swapBuffers(self: Self) void {
        glfw.glfwSwapBuffers(self.handle);
    }

    pub fn windowShouldClose(self: Self) bool {
        return if (glfw.glfwWindowShouldClose(self.handle) == 0) false else true;
    }
};

