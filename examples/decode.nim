import bpg, os

proc writePPM(img, filename) =
  var imgInfo: ImageInfo
  discard img.getInfo(addr imgInfo)

  let (w,h) = (imgInfo.width.int, imgInfo.height.int)
  var rgbLine = newSeq[uint8](w * 3)

  var f = open(filename, fmWrite)
  f.writeln "P6\n", w, " ", h, "\n255"

  discard img.start(OUTPUT_FORMAT_RGB24)
  for y in 1..h:
    discard img.getLine(addr rgbLine[0])
    discard f.writeBuffer(addr rgbLine[0], w * 3)

  f.close()

if paramCount() != 1:
  stderr.writeln "Usage: decode img.bpg"
  quit 1

var
  buf = readFile paramStr(1)
  img = bpg.open()

if img.decode(cast[ptr uint8](addr buf[0]), buf.len.cint) < 0:
  stderr.writeln "Could not decode image"
  quit 2

img.writePPM("out.ppm")
img.close()
