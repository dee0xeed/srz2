
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

pub const Ranker = struct {
    const ORDER = 3;

    ctx: u32 = 0,
    // per context value ranked lists, 4 bytes each
    list: []u32 = undefined,

    pub fn init(a: Allocator) !Ranker {

        var ranker = Ranker{};
        const len = @as(u32, 1) << (8 * ORDER);
        ranker.list = try a.alloc(u32, len);
        mem.set(u32, ranker.list, 0);
        return ranker;
    }

    pub inline fn update(self: *Ranker, s: u8, i: u32) void {

        var list = self.list[self.ctx];

        switch (i) {

            0 => {
                // not in the list
                const b3 = (list & 0x00ff_0000) << 8;  // b3 <- b2
                const b2 = (list & 0x0000_ff00) << 8;  // b2 <- b1
                const b1 = (list & 0x0000_00ff) << 8;  // b1 <- b0
                list = b3 | b2 | b1 | s;
            },

            1 => {
                // leave as is
            },

            2 => {
                const b1 = (list & 0x0000_00ff) << 8;  // b1 <- b0
                const b0 = (list & 0x0000_ff00) >> 8;  // b0 -> b1
                list &= 0xffff_0000;
                list |= b1 | b0;
            },

            3 => {
                const b2 = (list & 0x0000_ff00) << 8;  // b2 <- b1
                const b1 = (list & 0x0000_00ff) << 8;  // b1 <- b0
                const b0 = (list & 0x00ff_0000) >> 16; // b2 -> b0
                list &= 0xff00_0000;
                list |= b2 | b1 | b0;
            },

            4 => {
                const b3 = (list & 0x00ff_0000) << 8;  // b3 <- b2
                const b2 = (list & 0x0000_ff00) << 8;  // b2 <- b1
                const b1 = (list & 0x0000_00ff) << 8;  // b1 <- b0
                const b0 = (list & 0xff00_0000) >> 24; // b3 -> b0
                list = b3 | b2 | b1 | b0;
            },

            else => unreachable,
        }

        self.list[self.ctx] = list;
        self.ctx = ((self.ctx << 5) + s) & 0x00ffffff; // 3 byte hash of 4 bytes context
    }
};
