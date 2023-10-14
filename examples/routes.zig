const std = @import("std");
const router = @import("router");
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const Handler = router.Handler;

// Sample handler functions
fn handleGet(request: any) any {
    std.debug.print("Handled GET request for path '{}'\n", .{ request });
}

fn handlePost(request: any) any {
    std.debug.print("Handled POST request for path '{}'\n", .{ request });
}

pub fn main() void {
    // Initialize routes
    const allocator = gpa.allocator();
    var routes = router.init(allocator);
    defer router.deinit(&routes);

    // Add some sample routes
    routes.addResource(&[_][]u8{ "users" }, router.HttpMethod.GET, handleGet);
    routes.addResource(&[_][]u8{ "users", "create" }, router.HttpMethod.POST, handlePost);

    // Simulate a request coming in
    simulateRequest(&routes, "users", router.HttpMethod.GET);
    simulateRequest(&routes, "users/create", router.HttpMethod.POST);
}

fn simulateRequest(routes: *router.Routes, path: []const u8, method: router.HttpMethod) void {
    if (routes.routes.get(path)) |route| {
        if (route.handlers.get(method)) |handler| {
            handler(path);
        } else {
            std.debug.print("No handler found for method '{}'\n", .{ method });
        }
    } else {
        std.debug.print("No route found for path '{}'\n", .{ path });
    }
}

