const std = @import("std");
const utils = @import("utils.zig");
const MethodParseError = utils.MethodParseError;
const Method = utils.Method;

const Request = @This();

// リクエストライン
method: Method,
path: []u8,
version: Version,

// ヘッダー
headers: []Header,

// 本文
body: []u8,

pub const ParseError = MethodParseError || error{};

const ParserState = enum {
    // リクエストライン
    method,
    path,
    version,
};

pub fn parse(data: []u8) ParseError!Request {
    var index = 0;
    var state: ParserState = .method;

    while (index < data.len) : (index += 1) {
        const text = data[index];

        switch (state) {
            .method => {
                state = .path;
            },
        }
    }
}

pub const Version = enum {
    @"HTTP/1.0",
    @"HTTP/1.1",
};

pub const Header = struct {
    key: []u8,
    value: []u8,
};
