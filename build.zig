const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .os_tag = .linux,
            .cpu_arch = .x86_64,
        },
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    const http = b.addModule("http", .{
        .root_source_file = b.path("lib/http/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const net = b.addModule("net", .{
        .root_source_file = b.path("lib/net/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const nanoid = b.dependency("nanoid", .{}).module("nanoid");

    const exe = b.addExecutable(.{
        .name = "mini_social",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "http", .module = http },
                .{ .name = "nanoid", .module = nanoid },
                .{ .name = "net", .module = net },
            },
        }),
    });

    b.installArtifact(exe);
}
