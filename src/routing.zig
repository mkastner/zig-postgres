const std = @import("std");
const HashMap = std.HashMap;
const helpers = @import("helpers");

const Self = @This();


const HttpMethod = enum {
    GET,
    POST,
    PUT,
    DELETE,
    HEAD,
    OPTIONS,
    PATCH,
    TRACE,
    CONNECT,
};

const Route = struct {
    handlers: HashMap(HttpMethod, Route),
};

const Routes = struct {
    routes: HashMap([]u8, Route),
    addResources: fn(resources: [][]u8, handlers: []u8) void {
        const path 

        const route = Route{
            .handlers = HashMap(HttpMethod, Route).init(allocator),
        };
        _ = route;
    },
};


pub fn init( allocator: std.mem.Allocator) Routes {

   const routes = Routes{
       .routes = HashMap([]u8, Route).init(allocator),
   };
   _ = routes;

}

pub fn deinit(self: Self) void {
    self.routes.deinit(); 
}
