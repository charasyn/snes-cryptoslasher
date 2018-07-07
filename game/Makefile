output  := game.sfc

# make sure main.asm comes first
sources := main.asm coin.asm consts.asm explosion.asm gfxstuff.asm memory.asm obj.asm tools.asm
data    := 
images  := gfx/coin-4bpp.png gfx/explosion-4bpp.png
audio   := 

data_interim_targets := $(images:=.chr) $(audio:=.bin)
data_interim_all := $(data_interim_targets) $(images:=.pal)

all: $(output)

.PHONY: all clean

$(output): $(sources) $(data) $(data_interim_targets)
	bass -create -o $@ $< || rm -v $@

%-4bpp.png.chr: %-4bpp.png
	../tools/imagetosnes.py module=img8x8tosnes4bpp chrin=$< chrout=$<.chr palout=$<.pal

clean:
	rm -v $(output) $(data_interim_all) || true
