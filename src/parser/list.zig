const std = @import("std");
const List = @This();

allocator: std.mem.Allocator,
coordinates: std.ArrayList(usize),
lists: std.ArrayList([][2]usize),

pub fn init(allocator: std.mem.Allocator) List {
    return .{
        .allocator = allocator,
        .coordinates = std.ArrayList(usize).init(allocator),
        .lists = std.ArrayList([][2]usize).init(allocator),
    };
}

pub fn deinit(list: List) void {
    list.lists.deinit();
    list.coordinates.deinit();
}

pub fn fill(list: *List, content: []const u8) !void {
    var idx: usize = 1;
    var in_list: u1 = 0;

    while (idx < content.len - 2) : (idx += 1) {
        const prev = content[idx - 1];
        const curr = content[idx];
        const next = content[idx + 1];

        if (curr == '\n' and in_list > 0) {
            in_list = 0;
            try list.coordinates.append(idx);
            continue;
        }

        if (prev == ' ' and curr == '-' and next == ' ') {
            in_list = 1;
            try list.coordinates.append(idx);
            continue;
        }
    }

    var i: usize = 0;
    var prev: usize  = 0;
    var buf_list = std.ArrayList([2]usize).init(list.allocator);
    defer buf_list.deinit();
    
    while (list.coordinates.items.len > 1 and i < list.coordinates.items.len - 1) : (i += 2) {
        const items = buf_list.items;
        const start = list.coordinates.items[i];
        const end = list.coordinates.items[i + 1];

        const diff = start - prev;

        if (diff > 5 and items.len > 0) {
            const copy = try buf_list.clone();
            buf_list.clearAndFree();
            try list.lists.append(copy.items);
        }

        try buf_list.append([_]usize{start+2, end});
        prev = end;
    }

    if (buf_list.items.len > 1) {
        const copy = try buf_list.clone();
        buf_list.clearAndFree();
        try list.lists.append(copy.items);
    }
}

