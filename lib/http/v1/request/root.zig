const std = @import("std");
const mem = std.mem;

const Request = @This();

state: ParserState = .method,

// リクエストライン
method: Method = null,
path: []u8 = null,
version: Version = null,

// ヘッダー
headers: []Header = null,

// 本文
body: []u8 = null,

pub const ParseError = error{
    /// 改行コードを予期していたが、それ以外のものが来た場合のエラー
    InvalidNewlineCode,
    /// メソッドが見つからなかった場合
    InvalidMethod,
    /// パスの長さが255文字を超えた場合
    OutOfPathLength,
    /// 存在しないバージョンだった場合
    InvalidHTTPVersion,
};

const ParserState = enum {
    // リクエストライン
    method,
    path,
    version_h, // HTTP を一文字ずつ
    version_ht,
    version_htt,
    version_separator, // スラッシュ「/」
    version_major, // [メジャーバージョン].[マイナーバージョン]
    version_period,
    version_minor,

    // 改行コード
    separator_transition_header_CR,
    separator_transition_header_LF,

    // ヘッダー
    header_key,
    header_separator_colon, // :
    header_separator_space,
    header_value,

    header_CR,
    header_LF,

    separator_transition_body_CR, // bodyへの移行
    separator_transition_body_LF,

    // body
    body,
    done,
};

pub fn parse(request: *Request, data: []u8) ParseError!void {
    var startline: usize = 0;
    var index: usize = 0;

    var method: Method = undefined;
    var path: [255]u8 = undefined;

    // チャンクで少しずつロードされてっても、このState Machineが維持される
    while (index < data.len) : (index += 1) {
        const char = data[index];

        switch (request.state) {
            // リクエストライン
            .method => {
                // 8文字以上のHTTPメソッドはないので撤収
                if (index > 8) return error.InvalidMethod;

                if (char != ' ') continue;

                method = std.meta.stringToEnum(Method, data[0..index]) orelse return error.InvalidMethod;
                startline = index + 1;
                request.state = .path;
            },
            .path => {
                // パスを255文字に制限
                if ((index - startline) > 256) {
                    return error.OutOfPathLength;
                }

                if (char != ' ') continue;

                path = data[startline..index];
                startline = index + 1;
                request.state = .version_h;
            },
            // switch文は、if文と比べコンパイラーが最適化しやすいので一斉置き換え
            .version_h => switch (char) {
                'H' => request.state = .version_ht,
                else => return error.InvalidHTTPVersion,
            },
            .version_ht => switch (char) {
                'T' => request.state = .version_htt,
                else => return error.InvalidHTTPVersion,
            },
            .version_htt => switch (char) {
                'T' => request.state = .version_http,
                else => return error.InvalidHTTPVersion,
            },
            .version_http => switch (char) {
                'P' => request.state = .version_separator,
                else => return error.InvalidHTTPVersion,
            },
            .version_separator => switch (char) {
                '/' => request.state = .version_number,
                else => return error.InvalidHTTPVersion,
            },
            .version_major => switch (char) {
                '1' => request.state = .version_period,
                else => return error.InvalidHTTPVersion,
            },
            .version_period => switch (char) {
                '.' => request.state = .version_minor,
                else => return error.InvalidHTTPVersion,
            },
            .version_minor => {
                switch (char) {
                    '0' => request.version = .@"HTTP/1.0",
                    '1' => request.version = .@"HTTP/1.1",
                    else => return error.InvalidHTTPVersion,
                }

                request.state = .separator_transition_header_CR;
            },
            .separator_transition_header_CR => switch (char) {
                '\r' => request.state = .separator_transition_header_LF,
                else => return error.InvalidNewlineCode,
            },
            .separator_transition_header_LF => switch (char) {
                '\n' => request.state = .header_key,
                else => return error.InvalidNewlineCode,
            },
            .header_key => switch (char) {},
        }
    }
}

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

pub const Version = enum {
    @"HTTP/1.0",
    @"HTTP/1.1",
};

pub const Header = struct {
    key: []u8,
    value: []u8,
};
