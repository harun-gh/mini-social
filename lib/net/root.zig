const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const TCPServer = @import("./tcp/root.zig");

const Server = @This();

io: Io,
address: Io.net.IpAddress,

// 正常なdeinitのため
io_uring: Io.Uring,

// プロトコル
TCP: TCPServer,

pub fn init(self: *Server, address: Io.net.IpAddress, allocator: Allocator) !void {
    try self.io_uring.init(allocator, .{
        .log2_ring_entries = 10,
        // .thread_limit = 0,
        .sync_limit = .limited(1),
        .backing_allocator_needs_mutex = false,
    });
    errdefer self.io_uring.deinit();

    self.io = self.io_uring.io();
    self.address = address;
}

pub fn serve() !void {}

pub fn deinit(self: *Server) !void {
    self.io_uring.deinit();
}
