const std = @import("std");
const Io = std.Io;

const Server = @import("net");

pub fn main(init: std.process.Init) !void {
    var gpa = init.gpa;

    var server: Server = undefined;

    // http処理のメモリ
    const usable_server_malloc = try gpa.alloc(u8, 512 * 1024 * 1024);
    var fba: std.heap.FixedBufferAllocator = .init(usable_server_malloc);
    const server_allocator = fba.allocator();

    const address = try Io.net.IpAddress.parseIp4("127.0.0.1", 8080);
    std.debug.print("Address parsed: {any}\n", .{address});

    try server.init(&address, server_allocator); // 512 MB
    defer server.deinit();

    try server.serve();
}
