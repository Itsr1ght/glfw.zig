
var procs: gl.ProcTable = undefined;

const vertex_shader_src: [*]const u8 = 
    \\#version 330 core
    \\layout(location = 0) in vec3 a_pos;
    \\
    \\void main(){
    \\  gl_Position = vec4(a_pos, 1.0);
    \\}
    ;

const fragment_shader_src: [*]const u8 = 
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main(){
    \\  FragColor = vec4(1.0f, 0.0f, 0.0f, 1.0f);
    \\}
    ;

pub fn main() !u8 {
    try glfw.init();
    defer glfw.terminate();
    
    const window = try glfw.Window.init(640, 400, "Hello Zig", null, null);
    defer window.deinit();

    window.makeContextCurrent();
    
    if (!procs.init(glfw.GetProcAddress)) return error.GLInitFailed;
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    //
    // creating the Vertex Array Objects and Buffers
    //

    const vertices = [_]f32{
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0,
    };

    var VBO: c_uint = 0;
    gl.GenBuffers(1, @as([*c]c_uint, @ptrCast(&VBO)));
    defer gl.DeleteBuffers(1, @as([*c]c_uint, @ptrCast(&VBO)));

    var VAO: c_uint = 0;
    gl.GenVertexArrays(1, @as([*c]c_uint, @ptrCast(&VAO)));
    defer gl.DeleteVertexArrays(1, @as([*c]c_uint, @ptrCast(&VAO)));

    gl.BindVertexArray(VAO);

    gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.BufferData(gl.ARRAY_BUFFER, 
        @sizeOf(@TypeOf(vertices)),
        @as(*const anyopaque, @ptrCast(&vertices)),
        gl.STATIC_DRAW
    );

    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);
    gl.EnableVertexAttribArray(0);

    //
    // Shader Stuff
    //
    
    const vertShader: c_uint = gl.CreateShader(gl.VERTEX_SHADER);
    defer gl.DeleteShader(vertShader);
    const fragShader: c_uint = gl.CreateShader(gl.FRAGMENT_SHADER);
    defer gl.DeleteShader(fragShader);

    //compiling vertex shader
    
    gl.ShaderSource(vertShader, 1, @as([*]const [*]const u8, @ptrCast(&vertex_shader_src)), null);
    gl.CompileShader(vertShader);

    //compiling fragment shader
    
    gl.ShaderSource(fragShader, 1, @as([*]const [*]const u8, @ptrCast(&fragment_shader_src)), null);
    gl.CompileShader(fragShader);
    
    //creating program and linking shader
    
    const shaProgram: c_uint = gl.CreateProgram();
    defer gl.DeleteProgram(shaProgram);
    gl.AttachShader(shaProgram, vertShader);
    gl.AttachShader(shaProgram, fragShader);
    gl.LinkProgram(shaProgram);


    while(!window.ShouldClose()){

        gl.ClearColor(0.3, 0.3, 0.3, 1.0);
        gl.Clear(gl.COLOR_BUFFER_BIT);

        gl.UseProgram(shaProgram);
        gl.BindVertexArray(VAO);
        gl.DrawArrays(gl.TRIANGLES, 0, 3);

        window.swapBuffers();
        glfw.pollEvents();
    }
    return 0;
}

const std = @import("std");
const glfw = @import("glfw");
const gl = @import("gl");
