const std = @import("std");
const Metadata = @import("parser/metadata.zig");
const List = @import("parser/list.zig");

const input = @embedFile("Index.norg");
pub fn main() !void {
    const metadata = try Metadata.extract(input);
    std.debug.print("{any}\n", .{metadata});

    var buf: [1024 * 1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var list = List.init(fba.allocator());
    defer list.deinit();

    try list.fill(input[metadata.end..]);
    for(list.lists.items, 0..) |it, idx| {
        std.debug.print("List no {d}\n", .{idx + 1});

        for (it) |item| {
            std.debug.print("({d}|{d}): {s}\n", .{item[0], item[1], input[metadata.end+item[0]..metadata.end+item[1]]});
        }
    }
}

