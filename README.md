# glfw.zig

Binding for glfw for zig 0.15.1
Currently WIP

## Usage

``` 
zig fetch --save "git+https://github.com/Itsr1ght/glfw.zig"
```

on build.zig
```zig
const glfw_package = b.dependency("glfw_zig",
    .target = target,
    .optimize = optimize,
    .link_type = .static // link type with glfw library it can be : system, static, dynamic
)
exe.root_module.addImport("glfw", glfw_package.module("glfw"));

// OPTIONAL: add this if the link_type is set to dynamic otherwise it will be ignored
// Add this line to last of line
if(glfw_package.builder.user_input_options.get("link_type")) |link_type|{
    if(std.mem.eql(u8, link_type.value.scalar, "dynamic")){
        exe.linkLibrary(glfw_package.artifact("glfw"));
        const glfw_artifact = glfw_package.artifact("glfw");
        const install_glfw_artifact = b.addInstallArtifact(glfw_artifact,
            .{.dest_dir = .{.override = .bin}}
        );
        install_step.dependOn(&install_glfw_artifact.step);
    }
}
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
