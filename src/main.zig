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

    const address = try Io.net.IpAddress.parse("127.0.0.1", 80);

    try server.init(address, server_allocator); // 512 MB
    defer server.deinit();

    server.serve();
}
