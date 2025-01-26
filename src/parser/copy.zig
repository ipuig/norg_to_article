const std = @import("std");

pub fn copy(src_path: []const u8, dst_path: []const u8) !void {
    var src = try std.fs.openDirAbsolute(src_path, .{ .iterate = true });
    defer src.close();

    const cwd = std.fs.cwd();

    cwd.makeDir(dst_path) catch |err| switch(err) {
        std.fs.Dir.MakeError.PathAlreadyExists => {},
        else => unreachable
    };

    var dst = try cwd.openDir(dst_path, .{ .iterate = true });
    defer dst.close();

    var root = src.iterate();
    while (try root.next()) |child| {
        switch (child.kind) {
            .directory => try copyDir(child.name, src, dst),
            .file => 
                if (child.name.len >= 4 and std.mem.eql(u8, "norg", child.name[child.name.len-4..child.name.len])) {}
                else try std.fs.Dir.copyFile(src, child.name, dst, child.name, .{}),
            else => continue
        }
    }
}

fn copyDir(path: []const u8, src: std.fs.Dir, dst: std.fs.Dir) !void {
    dst.makeDir(path) catch |err| switch (err) {
        std.fs.Dir.MakeError.PathAlreadyExists => {},
        else => return err
    };

    var new_dst = try dst.openDir(path, .{ .iterate = true });
    defer new_dst.close();

    var source = try src.openDir(path, .{ .iterate = true });
    defer source.close();

    var root = source.iterate(); 
    while (try root.next()) |child| {
        switch (child.kind) {
            .directory => try copyDir(child.name, source, new_dst),
            .file => try std.fs.Dir.copyFile(source, child.name, new_dst, child.name, .{}),
            else => continue
        }
    }
}
