
const std = @import("std");
const Encoder = @import("bit-encoder.zig").Encoder;
const Ranker = @import("sr-model.zig").Ranker;

pub const SREncoder = struct {

    ranker: *Ranker = undefined,
    encoder: *Encoder = undefined,

    pub fn init(ranker: *Ranker, encoder: *Encoder) SREncoder {
        var sr_encoder = SREncoder{.ranker = ranker, .encoder = encoder};
        return sr_encoder;
    }

    /// emits Elias gamma code for the rank
    inline fn outputRank(self: *SREncoder, rank: u32) !void {

        var n0: u32 = 32 - @clz(rank) - 1;
        var k: isize = 0;

        while (k < n0) : (k += 1) {
            try self.encoder.take(0);
            self.encoder.bp.cx <<= 1;
        }

        k = n0;
        while (k >= 0) : (k -= 1) {
            var bit: u1 = @intCast(u1, (rank >> @intCast(u5, k)) & 1);
            try self.encoder.take(bit);
            self.encoder.bp.cx = (self.encoder.bp.cx << 1) | bit;
        }
    }

    inline fn outputLiteral(self: *SREncoder, sym: u8) !void {

        try self.outputRank(2);
        var k: isize = 7;
        while (k >= 0) : (k -= 1) {
            var bit: u1 = @intCast(u1, (sym >> @intCast(u3, k)) & 1);
            try self.encoder.take(bit);
            self.encoder.bp.cx = (self.encoder.bp.cx << 1) | bit;
        }
    }

    pub inline fn take(self: *SREncoder, sym: u8) !void {

        var list = self.ranker.list[self.ranker.ctx];

        var rank: u32 = 0;
        var k: u32 = 0;
        while (k < 4) : (k += 1) {
            if (sym == (list >> @intCast(u5, (k * 8))) & 0xff) {
                rank = k + 1;
                break;
            }
        }

        if (0 == rank) { // miss
            try self.outputLiteral(sym);
        } else {         // hit
            var r = if (1 == rank) rank else rank + 1;
            try self.outputRank(r);
        }

        self.ranker.update(sym, rank);
        self.encoder.bp.cx = (@as(u32, 1) << 11) | (rank << 8) | sym;
    }

    pub fn eof(self: *SREncoder) !void {
        try self.outputRank(6);
        try self.encoder.foldup();
    }
};
