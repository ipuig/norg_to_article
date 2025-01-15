const std = @import("std");
const Heading = @This();

allocator: std.mem.Allocator,
list: std.ArrayList([3]usize), // level, start, end

pub fn init(allocator: std.mem.Allocator) Heading {
    return .{
        .allocator = allocator,
        .list = std.ArrayList([3]usize).init(allocator)
    };
}

pub fn deinit(self: *Heading) void {
    self.list.deinit();
}

pub fn fill(self: *Heading, content: []const u8) !void {
    var lines = std.mem.splitAny(u8, content, "\n");
    while (lines.next()) |line| {
        const level = headingLevel(line);
        if (level[1] < 1) continue;
        try self.list.append([_]usize{level[1], lines.index.? - line.len + (level[0] + level[1]), lines.index.?});  
    }
}

fn headingLevel(text: []const u8) struct{usize, usize} {
    if (text.len < 1) return .{0, 0};
    const trimmed = std.mem.trimLeft(u8, text, " \t");
    var idx: usize = 0;
    var count: usize = 0;
    return .{text.len - trimmed.len,
        while (idx < trimmed.len and count <= 6): (idx += 1) {
            switch(trimmed[idx]) {
                '*' => count += 1,
                ' ' => break count,
                else => break 0
            }
        }
        else 0
    };
}
