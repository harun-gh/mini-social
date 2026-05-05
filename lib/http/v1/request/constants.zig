// HTTPヘッダー制限サイズ: 4KB (4096B)
pub const MaxHeaderSize: comptime_int = 8 * 1024;
// アロケーションするうえで、
pub const MaxHeaderArrayLength: comptime_int = 100;
