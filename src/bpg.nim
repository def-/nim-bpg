 {.deadCodeElim: on.}
when defined(windows): 
  const 
    bpglib* = "libbpg.dll"
elif defined(macosx): 
  const 
    bpglib* = "libbpg.dylib"
else: 
  const 
    bpglib* = "libbpg.so"
#
#  BPG decoder
#  
#  Copyright (c) 2014 Fabrice Bellard
# 
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
# 
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
# 
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
# 

type 
  DecoderContext* = object 
  
  ImageFormatEnum* {.size: sizeof(cint).} = enum 
    FORMAT_GRAY, FORMAT_420,  # chroma at offset (0.5, 0.5) (JPEG) 
    FORMAT_422,               # chroma at offset (0.5, 0) (JPEG) 
    FORMAT_444, FORMAT_420_VIDEO, # chroma at offset (0, 0.5) (MPEG2) 
    FORMAT_422_VIDEO          # chroma at offset (0, 0) (MPEG2) 
  ColorSpaceEnum* {.size: sizeof(cint).} = enum 
    CS_YCbCr, CS_RGB, CS_YCgCo, CS_YCbCr_BT709, CS_YCbCr_BT2020, CS_COUNT
  ImageInfo* = object 
    width*: uint32
    height*: uint32
    format*: uint8            # see BPGImageFormatEnum 
    has_alpha*: uint8         # TRUE if an alpha plane is present 
    color_space*: uint8       # see BPGColorSpaceEnum 
    bit_depth*: uint8
    premultiplied_alpha*: uint8 # TRUE if the color is alpha premultiplied 
    has_w_plane*: uint8       # TRUE if a W plane is present (for CMYK encoding) 
    limited_range*: uint8     # TRUE if limited range for the color 
    has_animation*: uint8     # TRUE if the image contains animations 
    loop_count*: uint16       # animations: number of loop, 0 = infinity 
  
  ExtensionTagEnum* {.size: sizeof(cint).} = enum 
    EXTENSION_TAG_EXIF = 1, EXTENSION_TAG_ICCP = 2, EXTENSION_TAG_XMP = 3, 
    EXTENSION_TAG_THUMBNAIL = 4, EXTENSION_TAG_ANIM_CONTROL = 5
  ExtensionData* = object 
    tag*: ExtensionTagEnum
    buf_len*: uint32
    buf*: ptr uint8
    next*: ptr ExtensionData

  DecoderOutputFormat* {.size: sizeof(cint).} = enum 
    OUTPUT_FORMAT_RGB24, OUTPUT_FORMAT_RGBA32, # not premultiplied alpha 
    OUTPUT_FORMAT_RGB48, OUTPUT_FORMAT_RGBA64, # not premultiplied alpha 
    OUTPUT_FORMAT_CMYK32, OUTPUT_FORMAT_CMYK64





const 
  DECODER_INFO_BUF_SIZE* = 16

proc open*(): ptr DecoderContext {.cdecl, importc: "bpg_decoder_open", 
                                   dynlib: bpglib.}
# If enable is true, extension data are kept during the image
#   decoding and can be accessed after bpg_decoder_decode() with
#   bpg_decoder_get_extension(). By default, the extension data are
#   discarded. 

proc keep_extension_data*(s: ptr DecoderContext; enable: cint) {.cdecl, 
    importc: "bpg_decoder_keep_extension_data", dynlib: bpglib.}
# return 0 if 0K, < 0 if error 

proc decode*(s: ptr DecoderContext; buf: ptr uint8; buf_len: cint): cint {.
    cdecl, importc: "bpg_decoder_decode", dynlib: bpglib.}
# Return the first element of the extension data list 

proc get_extension_data*(s: ptr DecoderContext): ptr ExtensionData {.cdecl, 
    importc: "bpg_decoder_get_extension_data", dynlib: bpglib.}
# return 0 if 0K, < 0 if error 

proc get_info*(s: ptr DecoderContext; p: ptr ImageInfo): cint {.cdecl, 
    importc: "bpg_decoder_get_info", dynlib: bpglib.}
# return 0 if 0K, < 0 if error 

proc start*(s: ptr DecoderContext; out_fmt: DecoderOutputFormat): cint {.cdecl, 
    importc: "bpg_decoder_start", dynlib: bpglib.}
# return the frame delay for animations as a fraction (*pnum) / (*pden)
#   in seconds. In case there is no animation, 0 / 1 is returned. 

proc get_frame_duration*(s: ptr DecoderContext; pnum: ptr cint; pden: ptr cint) {.
    cdecl, importc: "bpg_decoder_get_frame_duration", dynlib: bpglib.}
# return 0 if 0K, < 0 if error 

proc get_line*(s: ptr DecoderContext; buf: pointer): cint {.cdecl, 
    importc: "bpg_decoder_get_line", dynlib: bpglib.}
proc close*(s: ptr DecoderContext) {.cdecl, importc: "bpg_decoder_close", 
                                     dynlib: bpglib.}
# only useful for low level access to the image data 

proc get_data*(s: ptr DecoderContext; pline_size: ptr cint; plane: cint): ptr uint8 {.
    cdecl, importc: "bpg_decoder_get_data", dynlib: bpglib.}
# Get information from the start of the image data in 'buf' (at least
#   min(BPG_DECODER_INFO_BUF_SIZE, file_size) bytes must be given).
#
#   If pfirst_md != NULL, the extension data are also parsed and the
#   first element of the list is returned in *pfirst_md. The list must
#   be freed with bpg_decoder_free_extension_data().
#
#   BPGImageInfo.loop_count is only set if extension data are parsed.
#
#   Return 0 if OK, < 0 if unrecognized data. 

proc get_info_from_buf*(p: ptr ImageInfo; pfirst_md: ptr ptr ExtensionData; 
                        buf: ptr uint8; buf_len: cint): cint {.cdecl, 
    importc: "bpg_decoder_get_info_from_buf", dynlib: bpglib.}
# Free the extension data returned by bpg_decoder_get_info_from_buf() 

proc free_extension_data*(first_md: ptr ExtensionData) {.cdecl, 
    importc: "bpg_decoder_free_extension_data", dynlib: bpglib.}
