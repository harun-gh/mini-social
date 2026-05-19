const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const TCPServer = @import("./tcp/root.zig");

const Server = @This();

io: Io,
address: *const Io.net.IpAddress,

// 正常なdeinitのため
io_evented: Io.Evented,

// プロトコル
TCP: TCPServer,

pub fn init(self: *Server, address: *const Io.net.IpAddress, allocator: Allocator) !void {
    try self.io_evented.init(allocator, .{
        .log2_ring_entries = 10,
        // .thread_limit = 0,
        .sync_limit = .limited(1),
        .backing_allocator_needs_mutex = false,
    });
    errdefer self.io_evented.deinit();

    self.io = self.io_evented.io();

    const tcp_socket = try address.bind(self.io, .{
        .mode = .stream,

    });

    // Protocol
    try self.TCP.init(self.io, address, allocator);

    //
    self.address = address;
}

// pub fn serve(self: *Server) !void {
//     var accept_task = try self.io.concurrent(TCPServer.runAcceptLoop, .{&self.TCP});
//     var worker_task = try self.io.concurrent(TCPServer.runWorkerLoop, .{&self.TCP});

//     errdefer _ = accept_task.cancel(self.io) catch {};
//     errdefer _ = worker_task.cancel(self.io) catch {};

//     std.debug.print("Server running on {any}...\n", .{self.address});

//     try accept_task.await(self.io);
//     try worker_task.await(self.io);
// }

pub fn deinit(self: *Server) void {
    self.io_evented.deinit();
}
