// Extended std.io.net

const std = @import("std");
const linux = std.os.linux;
const Io = std.Io;
const net = Io.net;

const NetworkIo = @This();

// link: std.Io.VTable.netListenIp
pub fn netlistenIp(userdata: ?*anyopaque, address: *const net.IpAddress, options: net.IpAddress.ListenOptions) net.IpAddress.ListenError!net.Socket {
    _ = userdata; // 使わないので破棄

    const fb = linux.socket(address.listen(io: Io, options: BindOptions), socket_type: u32, protocol: u32)

    linux.listen(fd: i32, options.kernel_backlog)
}