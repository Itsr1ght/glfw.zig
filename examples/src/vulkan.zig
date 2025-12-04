const std = @import("std");
const vk = @import("vulkan");
const glfw = @import("glfw");

const application_name :[*:0]const u8 = "Hello Vulkan";
const required_layer_names = [_][*:0]const u8{"VK_LAYER_KHRONOS_validation"};

pub extern fn glfwCreateWindowSurface(instance: vk.Instance, window: *glfw.c.GLFWwindow, allocation_callbacks: ?*const vk.AllocationCallbacks, surface: *vk.SurfaceKHR) vk.Result;

fn debugUtilsMessengerCallback(severity: vk.DebugUtilsMessageSeverityFlagsEXT, msg_type: vk.DebugUtilsMessageTypeFlagsEXT, callback_data: ?*const vk.DebugUtilsMessengerCallbackDataEXT, _: ?*anyopaque) callconv(.c) vk.Bool32 {
    const severity_str = if (severity.verbose_bit_ext) "verbose" else if (severity.info_bit_ext) "info" else if (severity.warning_bit_ext) "warning" else if (severity.error_bit_ext) "error" else "unknown";

    const type_str = if (msg_type.general_bit_ext) "general" else if (msg_type.validation_bit_ext) "validation" else if (msg_type.performance_bit_ext) "performance" else if (msg_type.device_address_binding_bit_ext) "device addr" else "unknown";

    const message: [*c]const u8 = if (callback_data) |cb_data| cb_data.p_message else "NO MESSAGE!";
    std.debug.print("[{s}][{s}]. Message:\n  {s}\n", .{ severity_str, type_str, message });

    return .false;
}

pub fn main() !u8 {

    var arena: std.heap.ArenaAllocator = .init(std.heap.smp_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    try glfw.init();
    defer glfw.terminate();

    if (glfw.vulkanSupported() != glfw.c.GLFW_TRUE){
        std.log.err("GLFW could not find vulkan", .{});
        return error.NoVulkan;
    }

    var extent = vk.Extent2D{ .width = 800, .height = 600 };

    glfw.windowHint(glfw.c.GLFW_CLIENT_API, glfw.c.GLFW_FALSE);
    var window = try glfw.Window.init(
        @as(i32, @intCast(extent.width)),
        @as(i32, @intCast(extent.height)),
        application_name,
        null,
        null
    );
    defer window.deinit();

    extent.width, extent.height = blk: {
        const size = window.getFramebufferSize();
        break :blk .{@intCast(size.w), @intCast(size.h)}; 
    };

    const VulkanLoader = struct {
        fn loadFn(instance: vk.Instance, name: [*:0]const u8) vk.PfnVoidFunction {
            const vk_instance: glfw.c.VkInstance = @ptrFromInt(@intFromEnum(instance));
            return @ptrCast(glfw.c.glfwGetInstanceProcAddress(vk_instance, name));
        }
    };


    var vkb = vk.BaseWrapper.load(VulkanLoader.loadFn);

    var extension_names: std.ArrayList([*:0]const u8) = .empty;
    defer extension_names.deinit(allocator);

    try extension_names.append(allocator, vk.extensions.khr_portability_enumeration.name);
    try extension_names.append(allocator, vk.extensions.khr_get_physical_device_properties_2.name);

    var extension_count: u32 = 0;
    const required_extensions: [*c][*c]const u8 = glfw.getRequiredInstanceExtensions(&extension_count);
    try extension_names.appendSlice(allocator, @ptrCast(required_extensions[0..extension_count]));

    const instance = try vkb.createInstance(&.{
        .p_application_info = &.{
            .p_application_name = application_name,
            .application_version = @bitCast(vk.makeApiVersion(0,0,0,0)),
            .p_engine_name = application_name,
            .engine_version = @bitCast(vk.makeApiVersion(0,0,0,0)),
            .api_version = @bitCast(vk.API_VERSION_1_2),
    
        },
        .enabled_layer_count = required_layer_names.len,
        .pp_enabled_layer_names = @ptrCast(&required_layer_names),
        .enabled_extension_count = @intCast(extension_names.items.len),
        .pp_enabled_extension_names = extension_names.items.ptr,
        .flags = .{.enumerate_portability_bit_khr = true},
    }, null);

    const vki = try allocator.create(vk.InstanceWrapper);
    errdefer allocator.destroy(vki);

    vki.* = vk.InstanceWrapper.load(instance, vkb.dispatch.vkGetInstanceProcAddr.?);
    var instance_proxy = vk.InstanceProxy.init(instance, vki);
    errdefer instance_proxy.destroyInstance(null);

    const debug_messenger = try instance_proxy.createDebugUtilsMessengerEXT(&.{
        .message_severity = .{
            .warning_bit_ext = true,
            .error_bit_ext = true,
        },
        .message_type = .{
            .general_bit_ext = true,
            .validation_bit_ext = true,
        },
        .pfn_user_callback = debugUtilsMessengerCallback,
        .p_user_data = null,
        }, null
    );

    _ = debug_messenger;

    var surface: vk.SurfaceKHR = undefined; 
    if(glfwCreateWindowSurface(instance_proxy.handle, window.handle.?, null, &surface) != .success) {
        std.log.err("Cannot create a surface", .{});
        return 1;
    }

    errdefer instance_proxy.destroySurfaceKHR(surface, null);
    

    while(!window.ShouldClose()){
        
        glfw.pollEvents();
        window.swapBuffers();
    }
    return 0;
}
