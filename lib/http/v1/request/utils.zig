const std = @import("std");
const startsWith = std.mem.startsWith;

pub const MethodParseError = error{InvalidMethod};

// https://developer.mozilla.org/ja/docs/Web/HTTP/Reference/Methods
pub const Method = enum {
    GET,
    HEAD,
    POST,
    PUT,
    DELETE,
    CONNECT,
    OPTIONS,
    // https://developer.mozilla.org/ja/docs/Web/HTTP/Reference/Methods/TRACE
    // 「XST: Cross-Site Tracing」 攻撃の危険性があるためコメントアウト
    // TRACE,
    PATCH,
};

pub fn matchMethod(buffer: []u8) MethodParseError!Method {
    if (startsWith(buffer, "POST ")) {}
}
