const Quic = @This();

// QUIC v1/v2があるらしいけど、v2はテスト版でv1と同じ内容らしい
const quic_v1_salt = "0x38762cf7f55934b34d179ae6a4c80cadccbb7f0a";

// HTTP/3のQUICを実装するに当たって、対話の一番最初に送られてくるUDPパケットには鍵が入ってるので、それを扱うために先にTLS 1.3を実装しなきゃいけないかも？
pub fn init(self: *Quic) !void {}

pub fn parse(self: *Quic, content: []u8) !void {}

pub const PacketType = enum {
    Initial,
    Handshake,
    Short,
    @"0-RTT",
};
