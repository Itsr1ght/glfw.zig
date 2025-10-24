pub fn main() !u8 {
    try glfw.init();
    defer glfw.terminate();
    
    const window = try glfw.Window.init(640, 400, "Hello Zig", null, null);
    defer window.deinit();

    while(!window.windowShouldClose()){

        window.swapBuffers();
        glfw.pollEvents();
    }
    return 0;
}

const std = @import("std");
const glfw = @import("glfw");
