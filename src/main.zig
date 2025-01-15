const std = @import("std");
const Metadata = @import("parser/metadata.zig");
const List = @import("parser/list.zig");
const Paragraph = @import("parser/paragraph.zig");
const Heading = @import("parser/heading.zig");
const Widget = @import("parser/widget.zig");
const Parser = @import("parser/parser.zig");

pub fn main() !void {
    try Parser.toHTML("/Users/ipuig/.products/norg_html/src/Index.norg");
}
