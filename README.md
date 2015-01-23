# BPG (Better Portable Graphics) for Nim

This is a [Nim](http://nim-lang.org/) wrapper of [libbpg](http://bellard.org/bpg/). I'm using my [own fork](https://github.com/def-/libbpg) which creates a `libbpg.so`.

## Usage

For a usage example see [decode.nim](https://github.com/def-/nim-bpg/blob/master/examples/decode.nim). Since libbpg isn't included in most distributions we have to build it ourselves:

    $ git clone https://github.com/def-/libbpg.git
    $ cd libbpg
    $ make -j4
    $ cp libbpg.so ../nim-bpg
    $ cd ../nim-bpg

After this is done we can comfortably use the wrapper:

    $ nim c examples/decode
    $ examples/decode examples/lena512color.bpg
    $ gimp out.ppm

## Recreating the wrapper

To recreate the wrapper for new libbpg versions with a changed interface:

    $ patch -p1 < libbpg.h.patch
    patching file libbpg.h
    $ c2nim -o:bpg.nim libbpg.h
    Hint: operation successful (155 lines compiled; 0 sec total; 516.528KB) [SuccessX]

No manual interaction should be necessary.
