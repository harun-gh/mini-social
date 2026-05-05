const std = @import("std");
const mem = std.mem;

const constants = @import("constants.zig");
const MaxHeaderSize = constants.MaxHeaderSize;
const MaxHeaderArrayLength = constants.MaxHeaderSize;

const Request = @This();

// チャンク対応
state: ParserState = .method,
processed_index: usize = 0,
field_start_index: usize = 0,

// DoS/DDoS/DRDoS対策
header_size_count: usize = 0,

// リクエストライン
method: Method = null,
path: []u8 = null,
version: Version = null,

// ヘッダー
headers: []Header = null,

// 本文
body: []u8 = null,

pub const ParseError = error{
    // 改行コードを予期していたが、それ以外のものが来た場合のエラー
    InvalidNewlineCode,
    // メソッドが見つからなかった場合
    InvalidMethod,
    // パスの長さが255文字を超えた場合
    OutOfPathLength,
    // 存在しないバージョンだった場合
    InvalidHTTPVersion,
    // ヘッダー名に使えない文字が含まれていた場合
    InvalidHeaderKey,
    // ヘッダーの区切りが変だった場合、蹴り飛ばす
    InvalidHeaderFormat,
    // ヘッダー値に使えない文字が含まれていた場合
    InvalidHeaderValue,

    // 制限サイズオーバー
    HeaderFieldsTooLarge,
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
    header_skip_whitespaces, // ヘッダー名と値の間の空白は、オプショナルなことに注意
    header_value,

    separator_transition_body_newline,

    // body
    body,
    done,
};

pub fn parse(request: *Request, data: []u8) ParseError!void {
    var method: Method = undefined;
    var path: [255]u8 = undefined;

    // チャンクで少しずつロードされてっても、このState Machineが維持される
    while (request.processed_index < data.len) : (request.processed_index += 1) {
        // ヘッダーサイズやボディサイズの計算
        switch (@intFromEnum(request.state)) {
            @intFromEnum(ParserState.header_key)...@intFromEnum(ParserState.header_value) => {
                request.header_size_count += 1;

                if (request.header_size_count > MaxHeaderSize) return error.HeaderFieldsTooLarge;
            },
        }

        const char = data[request.processed_index];

        switch (request.state) {
            // リクエストライン
            .method => {
                // 8文字以上のHTTPメソッドはないので撤収
                if (request.processed_index > 8) return error.InvalidMethod;

                if (char != ' ') continue;

                method = std.meta.stringToEnum(Method, data[request.processed_index]) orelse return error.InvalidMethod;
                request.field_start_index = request.processed_index + 1;
                request.state = .path;
            },
            .path => {
                // パスを255文字に制限
                if ((request.processed_index - request.field_start_index) > 256) {
                    return error.OutOfPathLength;
                }

                if (char != ' ') continue;

                path = data[request.field_start_index..request.processed_index];
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
                '\n' => {
                    // ヘッダーに必須
                    request.field_start_index = request.processed_index + 1;
                    request.state = .header_key;
                },
                else => return error.InvalidNewlineCode,
            },

            // 修正: headerを持たないリクエストの場合、処理が終わらなくなってしまうバグが発生するので、`state: separator_transition_body_CR`を廃止

            // !!! 文字数制限必須 !!!
            // DoS/DDoS/DRDoS攻撃の温床になる

            .header_key => switch (char) {
                // 仕様書「rfc9110: HTTP Semantics / 5.6.2. Tokens」を参照: https://tex2e.github.io/rfc-translater/html/rfc9110.html#5-6-2--Tokens
                'a'...'z', 'A'...'Z', '0'...'9', '!', '#', '$', '%', '&', '\'', '*', '+', '-', '.', '^', '_', '`', '|', '~' => {
                    continue;
                },
                '\r' => {
                    if (request.field_start_index != request.processed_index) return error.InvalidNewlineCode;

                    request.state = .separator_transition_body_newline;
                },
                ':' => {
                    // 一文字目から「:」が来た場合、空のheaderは不正
                    if ((request.processed_index - request.field_start_index) == 0) return error.InvalidHeaderKey;

                    request.state = .header_separator_space;
                },
                else => return error.InvalidHeaderKey,
            },
            .header_separator_space => switch (char) {
                ' ' => {
                    request.state = .header_skip_whitespaces;
                },
                else => return error.InvalidHeaderFormat,
            },
            .header_skip_whitespaces => switch (char) {
                ' ' => continue,
                else => {
                    request.state = .header_value;
                    request.field_start_index = request.processed_index;
                    request.field_start_index -= 1;
                },
            },
            .header_value => switch (char) {
                // 仕様書「rfc9110: HTTP Semantics / 5.5. Field Values」を参照: https://tex2e.github.io/rfc-translater/html/rfc9110.html#5-5--Field-Values
                // 上では、許可されているが、Visible Characters外の参照をしてしまったら、バッファ(メモリー領域)の汚染のおそれあり
                'a'...'z', 'A'...'Z', '0'...'9', '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', '-', '.', '^', '_', '`', '|', '~', ' ' => {
                    continue;
                },
                else => {
                    return error.InvalidHeaderValue;
                },
            },

            .separator_transition_body_newline => switch (char) {
                '\n' => {
                    request.state = .body;
                },
                else => {
                    return error.InvalidNewlineCode;
                },
            },

            .body => switch (char) {},
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
