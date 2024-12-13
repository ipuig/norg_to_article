const std = @import("std");

fn bold(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const len = input.len;
    var buf = try allocator.alloc(u8, len + "<strong></strong>".len);
    return try std.fmt.bufPrint(&buf, "<strong>{s}</strong>", .{input});
}

fn italic(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const len = input.len;
    var buf = try allocator.alloc(u8, len + "<em></em>".len);
    return try std.fmt.bufPrint(&buf, "<em>{s}</em>", .{input});
}

fn underline(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const len = input.len;
    var buf = try allocator.alloc(u8, len + "<underline></underline>".len);
    return try std.fmt.bufPrint(&buf, "<underline>{s}</underline>", .{input});
}

fn link(text: []const u8, url: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const len = text.len + url.len;
    var buf = try allocator.alloc(u8, len + "<a href=\"\"></a>".len);
    return try std.fmt.bufPrint(&buf, "<a href=\"{s}\">{s}</a>", .{url, text});
}

fn heading(text: []const u8, level: usize, allocator: std.mem.Allocator) ![]u8 {
    const len = text.len;
    var buf = try allocator.alloc(u8, len + "<h1></h1>".len);
    return try std.fmt.bufPrint(&buf, "<h{d}>{s}</h{d}}", .{level, text, level});

}

fn paragraph(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const len = input.len;
    var buf = try allocator.alloc(u8, len + "<p></p>");
    return try std.fmt.bufPrint(&buf, "<p>{s}</p>", .{input});
}
