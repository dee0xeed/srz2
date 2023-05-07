
const std = @import("std");
const Decoder = @import("bit-decoder.zig").Decoder;
const Ranker = @import("sr-model.zig").Ranker;

pub const SRDecoder = struct {

    ranker: *Ranker = undefined,
    decoder: *Decoder = undefined,

    pub fn init(ranker: *Ranker, decoder: *Decoder) SRDecoder {
        var sr_decoder = SRDecoder{.ranker = ranker, .decoder = decoder};
        return sr_decoder;
    }

    pub fn give(self: *SRDecoder) !?u8 {

        var g: u32 = 0;
        var bit: u1 = 0;

        var n0: isize = -1;
        while (0 == bit) {
            bit = try self.decoder.give();
            self.decoder.bp.cx = (self.decoder.bp.cx << 1) | bit;
            g = (g << 1) | bit;
            n0 += 1;
        }

        var k: isize = 0;
        while (k < n0) : (k += 1) {
            bit = try self.decoder.give();
            self.decoder.bp.cx = (self.decoder.bp.cx << 1) | bit;
            g = (g << 1) | bit;
        }

        // EOF
        if (6 == g)
            return null;

        var sym: u8 = 0;
        if (2 == g) { // literal
            k = 0;
            while (k < 8) : (k += 1) {
                bit = try self.decoder.give();
                self.decoder.bp.cx = (self.decoder.bp.cx << 1) | bit;
                sym = (sym << 1) | bit;
            }
            g = 0;
        } else {
            var list = self.ranker.list[self.ranker.ctx];
            if (g > 1) g -= 1;
            sym = switch (g) {
                1 => @intCast(u8, list & 0xFF),
                2 => @intCast(u8, (list >> 8) & 0xFF),
                3 => @intCast(u8, (list >> 16) & 0xFF),
                4 => @intCast(u8, (list >> 24) & 0xFF),
                else => unreachable,
            };
        }

        self.ranker.update(sym, g);
        self.decoder.bp.cx = (@as(u32, 1) << 11) | (g << 8) | sym;
        return sym;
    }
};
