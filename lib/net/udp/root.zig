const std = @import("std");

const Io = std.Io;
const Socket = Io.net.Socket;
const Allocator = std.mem.Allocator;

allocator: Allocator,
socket: Socket,
io: Io,

const Protocol = @This();

pub fn init(self: *Protocol, io: Io, address: *const Io.net.IpAddress, allocator: Allocator) !void {
    const socket = try address.bind(io, .{
        .mode = .dgram,
        .protocol = .udp,
        .allow_broadcast = true,
    });
    errdefer socket.close(io);

    self.* = .{
        .allocator = allocator,
        .socket = socket,
        .io = io,
    };
}

// --------
//  未実装
// --------
pub fn serve(self: *Protocol) !void {
    return error.Undefined;

    self.allocator.alloc(
        Socket,
    );
    try self.socket.receive(
        self.io,
    );
}

pub fn deinit(self: *Protocol) void {
    self.socket.close(self.io);
}
