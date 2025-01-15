const std = @import("std");
const Metadata = @This();

/// If the post should be published
publish: bool,
/// Date from the metadata @document.post
/// Expects the format dd/mm/yyyy.
date: Date,
/// To obfuscate post content until a certain date
lock: bool,
/// byte position where the metadata ends—the start of the content
end: usize,

fn put(m: *Metadata, key: []const u8, val: []const u8) !void {
    if (std.mem.eql(u8, key, "date")) {
        var date_str = std.mem.tokenizeAny(u8, val, "/|: -");
        m.date = .{
            .day = try std.fmt.parseInt(usize, date_str.next().?, 10),
            .month = try std.fmt.parseInt(usize, date_str.next().?, 10),
            .year = try std.fmt.parseInt(usize, date_str.next().?, 10),
        };
    }

    if (std.mem.eql(u8, key, "publish")) {
        m.publish = isAffirmative(val);
    }

    if (std.mem.eql(u8, key, "lock")) {
        m.lock = isAffirmative(val);
    }
}

fn isAffirmative(input: []const u8) bool {
    const valid = .{"true", "yes"};
    const val = std.mem.trimLeft(u8, input, " ");
    for (val, 0..) |c, idx| {
        if (c != valid[0][idx] and c != valid[0][idx] - 32
        and c != valid[1][idx] and c != valid[1][idx] - 32)
        return false;
    }
    return true;
}

pub const Error = error {
missing_header
};


pub const Date = struct {
    year: usize,
    month: usize,
    day: usize,

    fn toString(
    date: Date,
    fmt: enum {default, american, reversed},
    allocator: std.mem.Allocator) ![]u8 {
        const buf = try std.mem.Allocator.alloc(allocator, u8, 12);
        return try switch (fmt) {
            .default => std.fmt.bufPrint(buf, "{d}/{d}/{d}", .{date.day, date.month, date.year}),
            .american => std.fmt.bufPrint(buf, "{d}/{d}/{d}", .{date.month, date.day, date.year}),
            .reversed => std.fmt.bufPrint(buf, "{d}/{d}/{d}", .{date.year, date.month, date.day})
        };
    }
};


pub fn extract(input: []const u8) !Metadata {
    if (input[0] != '@') return Metadata.Error.missing_header;
    var lines = std.mem.tokenizeAny(u8, input[1..], "\n");
    var metadata = Metadata{
        .publish = false,
        .date = Date{.day = 0, .month = 0, .year = 0},
        .lock = false,
        .end = 0,
    };

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "@end")) break;
        var i: usize = 0;

        const key = while (i < line.len) : (i += 1) {
            if (line[i] == ':') break line[0..i];
        } else "";

        if (i + 1 < line.len) {
            const val = line[i+1..];
            try metadata.put(key, val);
        }
    }

    metadata.end = lines.index;
    return metadata;
}
