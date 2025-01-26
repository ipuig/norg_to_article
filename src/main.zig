const std = @import("std");
const Metadata = @import("parser/metadata.zig");
const List = @import("parser/list.zig");
const Paragraph = @import("parser/paragraph.zig");
const Heading = @import("parser/heading.zig");
const Widget = @import("parser/widget.zig");
const Parser = @import("parser/parser.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var args = try std.process.argsWithAllocator(gpa.allocator());

    var no_args = args.skip();
    while (args.next()) |arg| { 
        try Parser.parse(arg);
        no_args = false;
        return;
    }

    if (no_args) try usage();
}

fn usage() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();
    try stdout.print("Expected posts folder path\n", .{});
    try bw.flush();

}
