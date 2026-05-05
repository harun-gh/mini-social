const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;

const TCPServer = @This();

// 問題点、同時に処理する量を指定しないとメモリーヤバいかも
// おそらくシングルスレッドなので、L1~L3キャッシュの面倒な立ち回りは発生しない

io: Io,
socket: Io.net.Socket.Handle,
queue: Io.Queue(Io.vtable.Socket),

allocator: Allocator,

pub fn init(io: Io, address: *const Io.net.IpAddress, allocator: Allocator) !*TCPServer {
    const self = try allocator.create(TCPServer);

    const socket = try io.vtable.netListenIp(io.userdata, address, .{
        .reuse_address = true,
        .kernel_backlog = 1024,
    });
    errdefer socket.close();

    const queue_buf = try allocator.alloc(@TypeOf(socket), 128);
    errdefer allocator.free(queue_buf);

    self.* = .{
        .io = io,
        .socket = socket.handle,
        .queue = .init(queue_buf),
        .allocator = allocator,
    };
    return self;
}

pub fn accept(self: *TCPServer) !Io.net.Socket {
    return self.io.vtable.netAccept(self.io.userdata, self.socket, .{});
}

pub fn runAcceptLoop(self: *TCPServer) !void {
    while (true) {
        const client_socket = try self.accept();

        try self.queue.putOne(self.io, client_socket);
    }
}

pub fn runWorkerLoop(self: *TCPServer) !void {
    while (true) {
        const client_socket = try self.queue.getOne(self.io);

        defer _ = self.io.vtable.netClose(self.io.userdata, self.socket) catch {};

        handleClient(self.io, client_socket) catch |err| {
            std.debug.print("Client error: {s}\n", .{@errorName(err)});
        };
    }
}
