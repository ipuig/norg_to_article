const std = @import("std");
const Parser = @This();

const List = @import("list.zig");
const Heading = @import("heading.zig");
const Widget = @import("widget.zig");
const Paragraph = @import("paragraph.zig");
const Metadata = @import("metadata.zig");
const Category = @import("post.zig").Category;
const dstDir = @import("dir.zig").dstDir;

pub fn parse(path: []const u8, allocator: std.mem.Allocator) !std.ArrayList(Category) {
    var stored_posts_src = try std.fs.openDirAbsolute(path, .{.iterate = true});
    defer stored_posts_src.close();

    var output = try dstDir("out");
    defer output.close();
    var root = stored_posts_src.iterate();

    var categories = std.ArrayList(Category).init(allocator);

    while (try root.next()) |entry| {
        if (entry.kind != .directory or std.mem.eql(u8, ".git", entry.name)) continue;
        var category = Category.init(allocator, entry.name);
        try category.findArticles(stored_posts_src, output, entry);
        try categories.append(category);
    }

    return categories;
}

pub fn parseArticle(input: []const u8, writer: anytype, allocator: std.mem.Allocator) !void {
    var list = List.init(allocator);
    defer list.deinit();
    var paragraph = Paragraph.init(allocator);
    defer paragraph.deinit();
    var heading = Heading.init(allocator);
    defer heading.deinit();
    var widget = Widget.init(allocator);
    defer widget.deinit();

    try paragraph.fill(input);
    try list.fill(input);
    try heading.fill(input);
    try widget.fill(input);

    var uls = list.lists;
    var ps = paragraph.list;
    var hs = heading.list;
    var ws = widget.list;

    var i: usize = 0;
    const n: usize = list.lists.items.len + paragraph.list.items.len + heading.list.items.len + widget.list.items.len;
    while (i < n): (i += 1) try render(select(&uls, &ps, &hs, &ws), input, writer);
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
