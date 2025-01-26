const std = @import("std");
const Parser = @This();

const List = @import("list.zig");
const Heading = @import("heading.zig");
const Widget = @import("widget.zig");
const Paragraph = @import("paragraph.zig");
const Metadata = @import("metadata.zig");
const copy = @import("copy.zig").copy;

pub fn parse(path: []const u8) !void {
    var stored_posts = try std.fs.openDirAbsolute(path, .{.iterate = true});
    defer stored_posts.close();

    var cwd = try std.fs.cwd().openDir(".", .{.iterate = true});
    defer cwd.close();
    cwd.makeDir("out") catch |err| switch(err) {
        std.fs.Dir.MakeError.PathAlreadyExists => {},
        else => unreachable
    };

    var output = try cwd.openDir("out", .{});
    defer output.close();

    var posts = stored_posts.iterate();
    while (try posts.next()) |category| {
        if (std.mem.eql(u8, ".git", category.name)) continue;
        std.debug.print("category: {s}\n", .{category.name});
        var post = try stored_posts.openDir(category.name, .{.iterate = true});
        defer post.close();

        var articles = post.iterate();
        while (try articles.next()) |article| {

            if (article.kind != .directory) continue;
            var source = try post.openDir(article.name, .{.iterate = true});
            defer source.close();
            var source_it = source.iterate();

            while (try source_it.next()) |f| {

                if (f.kind == .directory) {

                    const current_path = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{category.name, "/", article.name});
                    const in_path = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{path,  current_path});
                    const out_path = try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{"out/", current_path});
                    try copy(in_path, out_path);

                    continue;
                }

                var filename = std.mem.tokenizeAny(u8, f.name, ".");
                const file = filename.next();
                const extension = filename.next();

                if (extension != null and std.mem.eql(u8, extension.?, "norg")) {
                    var fbuf: [2048 * 100]u8 = undefined;
                    const text = try source.readFile(f.name, &fbuf);

                    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
                    defer _ = gpa.deinit();
                    const allocator = gpa.allocator();
                    var arena = std.heap.ArenaAllocator.init(allocator);
                    defer arena.deinit();

                    const new_path = try std.mem.concat(arena.allocator(), u8, &[_][]const u8{category.name, "/", article.name});
                    try output.makePath(new_path);

                    var destination = try output.openDir(new_path, .{ .iterate =  true});
                    defer destination.close();

                    const new_file_name = try std.mem.concat(arena.allocator(), u8, &[_][]const u8{file.?, ".html"});

                    var new_file = try destination.createFile(new_file_name, .{});
                    defer new_file.close();

                    try toHTML(text, &new_file);
                }
            }
        }
    }
}

pub fn toHTML(input: []const u8, new_file: *std.fs.File) !void {
    const metadata = try Metadata.extract(input);
    const content = input[metadata.end..];

    var buf: [1024 * 256]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const allocator = fba.allocator(); 

    var list = List.init(allocator);
    defer list.deinit();
    var paragraph = Paragraph.init(allocator);
    defer paragraph.deinit();
    var heading = Heading.init(allocator);
    defer heading.deinit();
    var widget = Widget.init(allocator);
    defer widget.deinit();

    try paragraph.fill(content);
    try list.fill(content);
    try heading.fill(content);
    try widget.fill(content);

    var uls = list.lists;
    var ps = paragraph.list;
    var hs = heading.list;
    var ws = widget.list;

    const writer = new_file.writer();
    var i: usize = 0;
    const n: usize = list.lists.items.len + paragraph.list.items.len + heading.list.items.len + widget.list.items.len;
    while (i < n): (i += 1) try render(select(&uls, &ps, &hs, &ws), content, writer);
}

const Rendable = union(enum) {
    li: [][2]usize,
    p: [2]usize,
    h: [3]usize,
    w: Widget.Wdef,
};

fn render(r: Rendable, content: []const u8, writer: anytype) !void {
    switch (r) {
        .li => |ul|  {
            try writer.print("<ul>\n", .{});
            for (ul) |li| try writer.print("<li>{s}</li>\n", .{content[li[0]..li[1]]});
            try writer.print("</ul>\n", .{});
        },
        .p => |paragraph| try writer.print("<p>{s}</p>\n", .{content[paragraph[0]..paragraph[1]]}),
        .h => |heading| try writer.print("<h{d}>{s}</h{d}>\n", .{heading[0], content[heading[1]..heading[2]], heading[0]}),
        .w => |widget| try writer.print("<p>{s}</p>\n", .{content[widget.bounds[0]..widget.bounds[1]]}),
    }
}

fn select(li: *std.ArrayList([][2]usize), p: *std.ArrayList([2]usize), h: *std.ArrayList([3]usize), w: *std.ArrayList(Widget.Wdef)) Rendable {
    const a = if (li.items.len >= 1) li.items[0][0][0] else null;
    const b = if (p.items.len >= 1) p.items[0][0] else null;
    const c = if (h.items.len >= 1) h.items[0][1] else null;
    const d = if (w.items.len >= 1) w.items[0].bounds[0] else null;

    const m = min(min(a, b), min(c, d));
    if (a == m and m != null) return .{ .li = li.orderedRemove(0) };
    if (b == m and m != null) return .{ .p = p.orderedRemove(0) };
    if (c == m and m != null) return .{ .h = h.orderedRemove(0) };
    return .{ .w = w.orderedRemove(0) };
}

fn min(a: ?usize, b: ?usize) ?usize {
    if (a == b and a == null) return null;
    if (a == null and b != null) return b.?;
    if (b == null and a != null) return a.?;
    return if (a.? < b.?) a.? else b.?;
}

test "lists" {
    var l = std.ArrayList(usize).init(std.testing.allocator);
    defer l.deinit();
    try l.append(1);
    try l.append(2);
    try l.append(3);
    try l.append(4);
    try l.append(5);
    try l.append(6);

    std.debug.print("at idx 0: {d}\n", .{l.items[0]});
    const pooped  = l.orderedRemove(0);
    std.debug.print("pooped {d}\n", .{pooped});
    std.debug.print("at idx 0: {d}\n", .{l.items[0]});
}
