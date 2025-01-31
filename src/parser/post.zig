const std = @import("std");

const Metadata = @import("metadata.zig");
const mkdir = @import("dir.zig").safeMakeDir;
const parse = @import("parser.zig").parseArticle;
const copy = @import("copy.zig").copy;

const Article = struct {
    resources: [][]const u8,
    name: []const u8,
    metadata: Metadata,
    content: []const u8,
};

pub const Category = struct {
    articles: std.ArrayList(Article),
    name: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, name: []const u8) Category {
        return .{
            .articles = std.ArrayList(Article).init(allocator),
            .name = name,
            .allocator = allocator
        };
    }

    pub fn deinit(self: Category) void {
        self.articles.deinit();
    }

    pub fn findArticles(self: *Category, src: std.fs.Dir, dst: std.fs.Dir, info: std.fs.Dir.Entry) !void {
        if (info.kind != .directory) return;
        var in = try src.openDir(self.name, .{ .iterate = true });
        defer in.close();

        var out = try mkdir(dst, self.name);
        defer out.close();

        var category = in.iterate();
        while (try category.next()) |article_entry| {
            if (article_entry.kind != .directory) continue;
            const name = article_entry.name;

            var inside_article_in = try in.openDir(name, .{ .iterate = true });
            defer inside_article_in.close();

            var inside_article_out = try mkdir(out, name);
            defer inside_article_out.close();

            var resources = std.ArrayList([]const u8).init(self.allocator);
            var string_builder = std.ArrayList(u8).init(self.allocator);
            var metadata = Metadata{
                .end = 0,
                .date = .{ .day = 0, .month = 0, .year = 0},
                .lock = false,
                .publish = false
            };

            var root = inside_article_in.iterate();
            while (try root.next()) |entry| {
                switch (entry.kind) {
                    std.fs.Dir.Entry.Kind.directory => {
                        try resources.append( try std.mem.Allocator.dupe(self.allocator, u8, entry.name));
                        var res_in = try inside_article_in.openDir(entry.name, .{ .iterate =  true });
                        defer res_in.close();
                        var res_out = try mkdir(inside_article_out, entry.name);
                        defer res_out.close();
                        try copy(res_in, res_out);
                    },
                    std.fs.Dir.Entry.Kind.file => {
                        if (entry.name.len <= 4 or !std.mem.eql(u8, "norg", entry.name[entry.name.len-4..entry.name.len])) continue;
                        var buf: [1024 * 500]u8 = undefined;
                        const text = try inside_article_in.readFile(entry.name, &buf);

                        var file = try inside_article_out.createFile("index.html", .{});
                        defer file.close();

                        metadata = try Metadata.extract(text);
                        const article_body = text[metadata.end..];
                        try parse(article_body, string_builder.writer(), self.allocator);
                        try file.writeAll(string_builder.items);

                    },
                    else => {}
                }
            }

            try self.articles.append(.{
                .name = name,
                .resources = resources.items,
                .content = string_builder.items,
                .metadata = metadata
            });
        }
    }

    pub fn asBytes(self: *Category, allocator: std.mem.Allocator) []u8 {

        var data = std.ArrayList(u8).init(allocator);
        var writer = data.writer();

        writer.writeByte('{');
        writer.print("\"{s}\": ", .{self.name});
        writer.writeByte('}');

    }

};
