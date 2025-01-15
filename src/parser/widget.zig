const std = @import("std");

const Widget = @This();
pub const Kind = enum {
    code,
    table,
};

pub const Wdef = struct {
    kind: Kind,
    bounds: [2]usize,
    opts: ?[2]usize,
};

allocator: std.mem.Allocator,
list: std.ArrayList(Wdef),

pub fn init(allocator: std.mem.Allocator) Widget {
    return .{
        .allocator = allocator,
        .list = std.ArrayList(Wdef).init(allocator)
    };
}

pub fn deinit(self: *Widget) void {
    self.list.deinit();
}

pub fn fill(self: *Widget, content: []const u8) !void {
    var idx: usize = 0;
    var new_line: bool = true;
    while (idx < content.len): (idx += 1) {
        switch (content[idx]) {
            '\n' => new_line = true,
            ' ', '\t' => continue,
            '@' => {
                if (!new_line) continue;
                new_line = false;
                if (widget(content[idx..], &idx)) |w| try self.list.append(w);
            },
            else => new_line = false,
        }
    }
}

fn widget(content: []const u8, idx: *usize) ?Wdef {
    var lines = std.mem.splitAny(u8, content, "\n");

    var start_offset: usize = 1;
    var ending: ?usize = null;

    var wdef: Wdef = .{
        .kind = .code,
        .opts = null,
        .bounds = [_]usize{0, 0}
    };

    if (lines.next()) |header| {
        var i: usize = 0;
        while (header[i] != ' ' and i < header.len): (i += 1) {}
        if (i < 5) return null;
        if (std.mem.eql(u8, header[0..i], "@code")) { wdef.kind = .code; }
        else if (std.mem.eql(u8, header[0..i], "@table")) { wdef.kind = .table; }
        else return null;

        i += 1;
        const start = idx.* + i;

        while (i < header.len and header[i] != '\n'): (i += 1) {}
        if (start != i) wdef.opts = [_]usize{start, i + idx.*};
        start_offset += header.len;
    }
    else return null;

    var ending_offset: usize = 0;
    ending = while (lines.next()) |body| {
        const trimmed = std.mem.trimLeft(u8, body, " \t");
        if (trimmed.len == 4 and std.mem.eql(u8, trimmed, "@end")) {
            ending_offset = body.len;
            break lines.index; 
        }
    } else null;

    if (ending) |end| {
        wdef.bounds[0] = idx.* + start_offset;
        wdef.bounds[1] = (idx.* + (end - ending_offset)) - 2;
        idx.* = idx.* + end;
    }
    else return null;
    return wdef;
}

test widget {
    var idx: usize = 0;
    const input = \\@code zig
    \\something
    \\ other thing
    \\    @end
    \\ something
    ;

    const content = 
    \\something
    \\ other thing
    ;

    const continuation = \\ something
    ;

    const w = widget(input, &idx);
    const opts = w.?.opts.?;

    try std.testing.expectEqualStrings("zig", input[opts[0]..opts[1]]);
    try std.testing.expectEqualSlices(u8, content, input[w.?.bounds[0]..w.?.bounds[1]]);
    try std.testing.expectEqualSlices(u8, continuation, input[idx..]);
}

test fill {

    var W = Widget.init(std.testing.allocator);
    defer W.deinit();

    const content = 
    \\somethign
    \\somethign
    \\somethign
    \\somethign
    \\somethign
    \\somethign bla bla @shouldn't trigger
    \\ this neither @code zig bla bla
    \\ this neither @code zig bla bla
    \\ but this should!!!
    \\               @code zig
    \\ fn main() !void {}
    \\ this does not close @end
    \\ but this next line will
    \\  @end
    \\ some more crap
    \\ yaaap
    \\ yaaap
    ;

    const expected_lang = "zig";
    const expected_cont = 
    \\ fn main() !void {}
    \\ this does not close @end
    \\ but this next line will
    ;

    try W.fill(content);
    try std.testing.expectEqual(1, W.list.items.len);
    const out = W.list.items[0];

    try std.testing.expectEqualStrings(expected_lang, content[out.opts.?[0]..out.opts.?[1]]);
    try std.testing.expectEqualSlices(u8, expected_cont, content[out.bounds[0]..out.bounds[1]]);
}
