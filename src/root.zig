const glfw = @cImport(
    @cInclude("GLFW/glfw3.h"),
);

const glfwError = error {
    InitFailed,
    InitWindowError,
    NoMonitorFound
};

// global functions
pub fn init() glfwError!void {
    const result = glfw.glfwInit();
    if (result == 0) {
        return glfwError.InitFailed;
    }
}
pub const pollEvents = glfw.glfwPollEvents;
pub const terminate = glfw.glfwTerminate;
pub const GetProcAddress = glfw.glfwGetProcAddress;

// struct

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
