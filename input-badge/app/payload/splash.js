/*
 * Makes plain black versions of an HDMI input's launch splash (the grey screen shown while an
 * input opens), the same size as LG's:
 *   node splash.js <LG's .astc> <LG's .png> <output folder>
 * writes black.astc (every block a solid black block, under LG's own header) and black.png.
 * Exits non-zero, writing nothing, if LG's files are not what is expected.
 */
var fs = require('fs');
var path = require('path');
var zlib = require('zlib');
var astcIn = process.argv[2], pngIn = process.argv[3], OUT = process.argv[4];

try {
  // ASTC: a 16-byte header (magic, block size, then width, height and depth as 24-bit numbers),
  // then one 16-byte block per block of pixels.
  var h = fs.readFileSync(astcIn).slice(0, 16);
  if (h.readUInt32LE(0) !== 0x5CA1AB13) throw new Error('the .astc splash is not a plain ASTC file');
  var bx = h[4], by = h[5], bz = h[6];
  var w = h[7] | h[8] << 8 | h[9] << 16, ht = h[10] | h[11] << 8 | h[12] << 16, d = h[13] | h[14] << 8 | h[15] << 16;
  var n = Math.ceil(w / bx) * Math.ceil(ht / by) * Math.ceil(d / bz);
  // A "void extent" block: one colour for the whole block, as RGBA in 16 bits each. Opaque black.
  var block = Buffer.from([0xfc, 0xfd, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0, 0, 0, 0xff, 0xff]);
  var astc = Buffer.alloc(16 + n * 16);
  h.copy(astc, 0);
  for (var i = 0; i < n; i++) block.copy(astc, 16 + i * 16);

  // PNG: LG's size, black, RGB.
  var p = fs.readFileSync(pngIn);
  if (p.toString('latin1', 12, 16) !== 'IHDR') throw new Error('the .png splash is not a PNG');
  var pw = p.readUInt32BE(16), ph = p.readUInt32BE(20);
  var raw = Buffer.alloc((pw * 3 + 1) * ph);           // each row: filter byte 0, then black pixels
  var crcTable = [];
  for (var c = 0; c < 256; c++) { var k = c; for (var j = 0; j < 8; j++) k = k & 1 ? 0xedb88320 ^ (k >>> 1) : k >>> 1; crcTable[c] = k >>> 0; }
  function crc(buf) { var x = 0xffffffff; for (var q = 0; q < buf.length; q++) x = crcTable[(x ^ buf[q]) & 0xff] ^ (x >>> 8); return (x ^ 0xffffffff) >>> 0; }
  function chunk(type, data) {
    var len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    var td = Buffer.concat([Buffer.from(type, 'latin1'), data]);
    var cs = Buffer.alloc(4); cs.writeUInt32BE(crc(td));
    return Buffer.concat([len, td, cs]);
  }
  var ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(pw, 0); ihdr.writeUInt32BE(ph, 4); ihdr[8] = 8; ihdr[9] = 2;
  var png = Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);

  fs.mkdirSync(OUT, { recursive: true });
  fs.writeFileSync(path.join(OUT, 'black.astc'), astc);
  fs.writeFileSync(path.join(OUT, 'black.png'), png);
  console.log('built ' + w + 'x' + ht);
} catch (e) {
  console.log(e.message);
  process.exit(1);
}
