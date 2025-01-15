const std = @import("std");
const Parser = @This();

const List = @import("list.zig");
const Heading = @import("heading.zig");
const Widget = @import("widget.zig");
const Paragraph = @import("paragraph.zig");
const Metadata = @import("metadata.zig");

pub fn toHTML(path: []const u8) !void {
    var file_buf: [1024 * 256]u8 = undefined;
    const file = try std.fs.openFileAbsolute(path, .{ .mode =  .read_only});
    defer file.close();

    const written = try file.reader().readAll(&file_buf);
    const input = file_buf[0..written];

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


    const out_file = try std.fs.createFileAbsolute(path, .{});
    defer out_file.close();

    var i: usize = 0;
    const n: usize = list.lists.items.len + paragraph.list.items.len + heading.list.items.len + widget.list.items.len;
    while (i < n): (i += 1) render(select(&uls, &ps, &hs, &ws), content);

}

const Rendable = union(enum) {
    li: [][2]usize,
    p: [2]usize,
    h: [3]usize,
    w: Widget.Wdef,
};

fn render(r: Rendable, content: []const u8) void {
    switch (r) {
        .li => |ul|  {
            std.debug.print("<ul>\n", .{});
            for (ul) |li| std.debug.print("<li>{s}</li>\n", .{content[li[0]..li[1]]});
            std.debug.print("</ul>\n", .{});
        },
        .p => |paragraph| std.debug.print("<p>{s}</p>\n", .{content[paragraph[0]..paragraph[1]]}),
        .h => |heading| std.debug.print("<h{d}>{s}</h{d}>\n", .{heading[0], content[heading[1]..heading[2]], heading[0]}),
        .w => |widget| std.debug.print("<p>{s}</p>\n", .{content[widget.bounds[0]..widget.bounds[1]]}),
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

