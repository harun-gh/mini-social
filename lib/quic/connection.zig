const std = @import("std");

const Connection = @This();

dcid: [20]u8 = [_]u8{0} ** 20,
dcid_len: u8 = 0,

const PacketState = enum {
    header,
    version,
    dcid_length,
    dcid,
    scid_length,
    scid,
    token_length,
    token,
    length,
    packet_number,
    payload,
};

// const PacketType = enum {
//     short,
//     long,
// };

const InitialPacketError = error{
    InvalidInitialPacket,
    InvalidFixedBit,
    InvalidQUICVersion,
};

// TLS handshake packetがここに来るらしい？
// cursor parser (state machine思想)
pub fn init(self: *Connection, initial_packet: []const u8) InitialPacketError!void {
    var current_index: usize = 0;
    var state: PacketState = .header;

    var packet_number_length: u8 = undefined;

    var dcid_len: u8 = undefined;
    var dcid: []u8 = undefined;

    var scid_len: u8 = undefined;
    var scid: u8 = undefined;

    while (current_index < initial_packet.len) : (current_index += 1) {
        const char = initial_packet[current_index];

        switch (state) {
            // [Is long header (0 or 1)] [Fixed Bit (1)] [Packet Type] [Reserved Bits] []
            .header => {
                // Long Packet前提
                if (((char & 0b10000000) >> 7) != 1) return error.InvalidInitialPacket;

                // QUICのバージョンは1しかないので、それ以外は蹴る
                if (((char & 0b01000000) >> 6) != 1) return error.InvalidFixedBit;

                // Packet Type
                if (((char & 0b00110000) >> 4) != 0) return error.InvalidInitialPacket;

                // Reserved Bits
                if ((char & 0b00001100) >> 2) return error.InvalidInitialPacket;

                // Packet Number Length
                packet_number_length = @as(u8, @truncate(char & 0b00000011)) + 1;

                state = .version;
            },
            .version => {
                const version = std.mem.readInt(
                    u32,
                    initial_packet[current_index .. current_index + 4],
                    .big,
                );

                if (version != 1) return error.InvalidQUICVersion;

                current_index += 4;

                state = .dcid_length;
            },
            .dcid_length => {
                dcid_len = char;

                state = .dcid;
            },
            .dcid => {
                dcid = initial_packet[current_index .. current_index + dcid_len];
                current_index += dcid_len;

                state = .scid_length;
            },
            .scid_length => {
                scid_len = scid;

                state = .scid;
            },
            .scid => {
                scid = initial_packet[current_index .. current_index + scid_len];
                current_index += scid_len;
            },
            .token_length => {},
        }
    }

    self.* = .{};
}
