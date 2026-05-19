const std = @import("std");
const Io = std.Io;

const Allocator = std.mem.Allocator;
const Socket = Io.net.Socket;

const Protocol = @This();

// 問題点、同時に処理する量を指定しないとメモリーヤバいかも
// おそらくシングルスレッドなので、L1~L3キャッシュの面倒な立ち回りは発生しない

io: Io,
socket: Socket,
queue: Io.Queue(Socket),
queue_buffer: []Socket,
allocator: Allocator,

pub fn init(self: *Protocol, io: Io, address: *const Io.net.IpAddress, allocator: Allocator) !void {
    const socket = try io.vtable.netListenIp(io.userdata, address, .{
        .reuse_address = true,
        .kernel_backlog = 1024,
    });
    errdefer io.vtable.netClose(io.userdata, &.{socket.handle});

    const queue_buffer = try allocator.alloc(Socket, 128);
    errdefer allocator.free(queue_buffer);

    self.* = .{
        .io = io,
        .socket = socket,
        .queue = .init(queue_buffer),
        .queue_buffer = queue_buffer,
        .allocator = allocator,
    };
}

pub fn deinit(self: *Protocol) !void {
    self.allocator.free(self.queue_buffer);
    self.io.vtable.netClose(self.io.userdata, &.{self.socket.handle});
}

// pub fn accept(self: *Protocol) Io.net.Server.AcceptError!Socket {
//     return self.io.vtable.netAccept(self.io.userdata, self.socket.handle, {});
// }

// pub fn runAcceptLoop(self: *Protocol) !void {
//     std.debug.print("registed AcceptLoop", .{});
        

//     while (true) {
//         const client_socket = try self.accept();
//         std.debug.print("[Accept] New client connected: fd={d}\n", .{client_socket.handle});

//         self.queue.putOne(self.io, client_socket) catch |err| {
//             std.debug.print("[Accept] Queue put failed: {any}\n", .{err});
//             self.io.vtable.netClose(self.io.userdata, &.{client_socket.handle});
//             continue;
//         };

//         std.debug.print("[Accept] Enqueued client: fd={d}\n", .{client_socket.handle});
//     }
// }

// pub fn runWorkerLoop(self: *Protocol) !void {
//     std.debug.print("registed WorkerLoop", .{});

//     while (true) {
//         const client_socket = try self.queue.getOne(self.io);

//         std.debug.print("[Worker] Dequeued client: fd={d}\n", .{client_socket.handle});

//         defer self.io.vtable.netClose(self.io.userdata, &.{client_socket.handle});
//     }
// }
