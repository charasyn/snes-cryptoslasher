arch snes.cpu
endian lsb

// standard lorom stuff
macro seek(variable offset) {
  origin ((offset & 0x7f0000) >> 1 | (offset & 0x7fff))
  base offset
}

include "../asm-common/defs.asm"
include "consts.asm"
include "memory.asm"

seek($008000)
fill $8000

include "../asm-common/header.asm"
include "../asm-common/gfx.asm"

seek($008000)
_rst:
    SNES_INIT(SLOWROM)

    LoadPAL(asset_data.ObjPalData,128,asset_data.ObjPalSize,0)
    LoadVRAM(asset_data.ObjGfxData,0x4000,asset_data.ObjGfxSize,0)

    jsr.w ClearOAM
    jsr.w UploadOAM

    sep #$30
    // This probably puts OAM tile data at $2000 in VRAM
    lda.b #$02
    sta.w REG_OBSEL
    // Enable sprites on main screen, disable everything on subscreen
    lda.b #$10
    sta.w REG_TM
    stz.w REG_TS
    // Set brightness to max, disable forced blank
    lda.b #$0f
    sta.w REG_INIDISP
    // Enable NMI (Vblank int.)? Maybe something else? I don't have a reference open
    lda.b #$81
    sta.w REG_NMITIMEN

    // Load starting coin data for demo into RAM
    // X contains the index, we want to go from len-1 to 0
    ldx.b # CoinData.length - 1
-
    lda.w CoinData,x
    sta.b mem.Objects.X,x
    dex
    bpl - // if X is not negative, branch

MainLoop:
    // Set main processing loop flag
    // This allows the VBlank handler to detect when the processing code is taking too long
    //   and to not update the screen to a partially completed state
    inc.w mem.MainLoopRunning

    jsr.w ClearOAM

    // Here is where we would want to do game logic:

    inc.b mem.FrameCount

    wdm #$10
    // Process the logical game objects
    jsr.w objects.Process

    // Build the secondary OAM table into the right format
    // We manipulate it in memory in an unpacked form, using only two bits per byte
    // We then have to pack 4 sets of 2 bits into one byte to make it how the PPU wants it
    jsr.w BuildOAM

    // Unset the flag to tell the NMI handler that it can do its stuff
    stz.w mem.MainLoopRunning
MainLoopWait:
    stz.w mem.NMIHappened

    // This is debugging code that tracks how long the main loop takes
    // Set A to 16-bit
    rep #$20
    // Clear low word of count
    stz.b mem.ProfilerCount
    // Clear high word of count
    stz.b mem.ProfilerCount+2
-   // Loop point
    // Increment the low word of count
    inc.b mem.ProfilerCount
    lda.b mem.ProfilerCount+2
    // If the low word overflows, then 1 will get added to the high word; otherwise, 0
    adc.w # 0
    sta.b mem.ProfilerCount+2
    // This could be done with a conditional increment, but this way it will take the
    //  same amount of time whether it overflows or not, leading to more consistent counts

    // If NMI didn't happen, loop again
    lda.w mem.NMIHappened
    beq -
    // Set A back to 8-bit
    sep #$20
    jmp MainLoop

_nmi:
    // Preserve state of all registers
    rep #$30
    pha
    phx
    phy
    sep #$20

    // If main loop is still running, don't update screen
    lda.w mem.MainLoopRunning
    bne NMILagFrame
MainNMI:
    // Put us into forced blank
    lda.b #$80
    sta.w REG_INIDISP

    jsr UploadOAM

    // Max brightness, no forced blank
    lda.b #$0f
    sta.w REG_INIDISP

    // Indicate that NMI completed
    inc.w mem.NMIHappened
EndOfInterrupt:
    rep #$30
    ply
    plx
    pla
    //rti
_irq:
_brk:
_cop:
    rti
NMILagFrame:
    inc.b mem.LagFrames
    bra EndOfInterrupt

include "coin.asm"
include "explosion.asm"
include "gfxstuff.asm"
include "tools.asm"
include "obj.asm" // this has to be included last due to constant determination stuff??

// This is in the format that it is in memory, see memory.asm -> Objects for more info
scope CoinData: {
start:
    dw 0,0,200*32,200*32
    dw 0,160*32,0,160*32
    db $04,$00,$00,$00
    db $03,$00,$00,$00
    db $01,$02,$01,$00
    db $00,$0c,$18,$24
end:
constant length(end - start)
}
    
print "\nEND OF BANK 1: 0x"
hexprint(pc())
print "\n"

print "\nMainLoop:     0x"
hexprint(MainLoop)
print "\nMainLoopWait: 0x"
hexprint(MainLoopWait)
print "\nNMI:          0x"
hexprint(_nmi)
print "\n"

seek($018000)
scope asset_data {
ObjGfxData:
    insert coin_gfx_data, "gfx/coin-4bpp.png.chr", 0, 0x2000
    insert explosion_gfx_data, "gfx/explosion-4bpp.png.chr", 0, 0x2000
EndOfObjGfxData:
constant ObjGfxSize(EndOfObjGfxData - ObjGfxData)

ObjPalData:
    insert coin_gfx_pal, "gfx/coin-4bpp.png.pal"
    insert explosion_gfx_pal, "gfx/explosion-4bpp.png.pal"
EndOfObjPalData:
constant ObjPalSize(EndOfObjPalData - ObjPalData)
}
