const std = @import("std");
const expect = std.testing.expect;
const print = std.debug.print;

const Color = enum {
    Red,
    Blue,
    Green,
    Yellow,
    Purple,
    Orange,
    Black,
    White,
    Cyan,
    Magenta,
};

const ITERATIONS: u64 = 1_000_000;

test "Performance: stringToEnum vs switch" {
    var timer = try std.time.Timer.start();

    const input = "Magenta";

    // 1. std.meta.stringToEnum の計測
    timer.reset();
    var i: u64 = 0;
    var result_a: ?Color = null;
    while (i < ITERATIONS) : (i += 1) {
        result_a = std.meta.stringToEnum(Color, input);
        std.mem.doNotOptimizeAway(result_a);
    }
    const time_a = timer.read();

    // 2. switch 文の計測
    timer.reset();
    i = 0;
    var result_b: ?Color = null;
    while (i < ITERATIONS) : (i += 1) {
        result_b = switch_string_to_enum(input);
        std.mem.doNotOptimizeAway(result_b);
    }
    const time_b = timer.read();

    print("\n--- Benchmark Results ({d} iterations) ---\n", .{ITERATIONS});
    print("std.meta.stringToEnum: {d:>10} ns\n", .{time_a});
    print("switch statement:      {d:>10} ns\n", .{time_b});
    print("Ratio (switch/std):    {d:.2}x\n", .{@as(f64, @floatFromInt(time_b)) / @as(f64, @floatFromInt(time_a))});
}

fn switch_string_to_enum(str: []const u8) ?Color {
    // コンパイラがハッシュ変換や長さチェックを最適化して組み込む
    return if (std.mem.eql(u8, str, "Red")) .Red else if (std.mem.eql(u8, str, "Blue")) .Blue else if (std.mem.eql(u8, str, "Green")) .Green else if (std.mem.eql(u8, str, "Yellow")) .Yellow else if (std.mem.eql(u8, str, "Purple")) .Purple else if (std.mem.eql(u8, str, "Orange")) .Orange else if (std.mem.eql(u8, str, "Black")) .Black else if (std.mem.eql(u8, str, "White")) .White else if (std.mem.eql(u8, str, "Cyan")) .Cyan else if (std.mem.eql(u8, str, "Magenta")) .Magenta else null;

    // 注: Zigの最新版で文字列switchが直接使える場合は以下がより効率的

    // return switch (str) {
    //     inline "Red", "Blue", "Green", "Yellow", "Purple",
    //            "Orange", "Black", "White", "Cyan", "Magenta" => |s| @field(Color, s),
    //     else => null,
    // };
}
