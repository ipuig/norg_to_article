const std = @import("std");

pub fn dstDir(path: []const u8) !std.fs.Dir {
    var cwd = try std.fs.cwd().openDir(".", .{.iterate = true});
    defer cwd.close();
    return safeMakeDir(cwd, path);
}

pub fn safeMakeDir(dir: std.fs.Dir, new_dir: []const u8) !std.fs.Dir {
    dir.makeDir(new_dir) catch |err| switch(err) {
        std.fs.Dir.MakeError.PathAlreadyExists => {},
        else => unreachable
    };
    return try dir.openDir(new_dir, .{});
}
