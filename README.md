# glfw.zig

Binding for glfw for zig 0.15.1

## Usage

``` 
zig fetch --save "git+https://github.com/Itsr1ght/glfw.zig"
```

on build.zig
```
const glfw_package = b.dependency("glfw_zig",
    .target = target,
    .optimize = optimize,
)
exe.root_module.addImport("glfw", glfw_package.module("glfw"))
```

## Example Code

```zig
const std = @import("std");
const glfw = @import("glfw");


pub fn main() !u8 {
    
    try glfw.init();
    

    defer glfw.terminate();

    const window = try glfw.Window.init(
        1080, 720, "Hello World", null, null
    );

    defer window.deinit();
    window.makeContextCurrent();

    while (!window.windowShouldClose()){
        window.swapBuffers();
        glfw.pollEvents();
    }

    return 0;
}

```
