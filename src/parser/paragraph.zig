const std = @import("std");
const Paragraph = @This();

allocator: std.mem.Allocator,
list: std.ArrayList([2]usize),

pub fn init(allocator: std.mem.Allocator) Paragraph {
    return .{
        .allocator = allocator,
        .list = std.ArrayList([2]usize).init(allocator)
    };
}

pub fn deinit(self: *Paragraph) void {
    self.list.deinit();
}

pub fn fill(self: *Paragraph, content: []const u8) !void {
    var idx: usize = 1;
    var start: usize = 0;
    var multi_line: bool = false;
    var lines = std.mem.splitAny(u8, content, "\n");

    while (lines.next()) |line|: (idx += 1) {

        const paragraph: bool, const offset: usize = isParagraph(line);

        if (!paragraph) {
            multi_line = false;
            continue;
        }

        const next: []const u8 = lines.peek() orelse "";
        const nextParagraph: bool, _ = isParagraph(next);

        if (multi_line) {
            if (nextParagraph) continue;
            try self.list.append([_]usize{start, lines.index.?});
            continue;
        }

        start = (lines.index.? - (line.len + 1)) + offset;
        if (nextParagraph) {
            multi_line = true;
            continue;
        }

        try self.list.append([_]usize{start, lines.index.?});
        multi_line = false;
    }
}

fn isParagraph(text: []const u8) struct{bool, usize} {
    const trimmed = std.mem.trimLeft(u8, text, " \t");
    if (trimmed.len < 1) return .{false, 0};
    return .{ (trimmed[0] >= 48 and trimmed[0] <= 57) or (trimmed[0] >= 65 and trimmed[0] <= 126),
        text.len - trimmed.len
    };
}
