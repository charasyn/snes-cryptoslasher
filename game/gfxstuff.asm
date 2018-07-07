// gfxstuff.asm
arch snes.cpu

scope UploadOAM: {
    stz.w REG_OAMADDL
    stz.w REG_OAMADDH

    stz.w REG_DMAP0             // Set DMA Mode (Write Byte, Increment Source) ($43X0: DMA Control)
    lda.b # REG_OAMDATA & 0xff  // Set Destination Register
    sta.w REG_BBAD0             // $43X1: DMA Destination
    ldx.w #mem.OAMBuffer        // Set Source Offset
    stx.w REG_A1T0L             // $43X2: DMA Source
    stz.w REG_A1B0              // $43X4: Source Bank
    ldx.w #512                  // OAM low table is 512 bytes of data
    stx.w REG_DAS0L             // $43X5: DMA Transfer Size/HDMA

    lda.b #$01 << 0 // Start DMA Transfer On Channel
    sta.w REG_MDMAEN     // $420B: DMA Enable
    nop

    stz.w REG_OAMADDL
    lda.b #$01                  // Select high table
    sta.w REG_OAMADDH

    stz.w REG_DMAP0             // Set DMA Mode (Write Byte, Increment Source) ($43X0: DMA Control)
    lda.b # REG_OAMDATA & 0xff  // Set Destination Register
    sta.w REG_BBAD0             // $43X1: DMA Destination
    ldx.w #mem.OAMBufferHighComp // Set Source Offset
    stx.w REG_A1T0L             // $43X2: DMA Source
    stz.w REG_A1B0              // $43X4: Source Bank
    ldx.w #32                  // OAM high table is 32 bytes of data
    stx.w REG_DAS0L             // $43X5: DMA Transfer Size/HDMA

    lda.b #$01 << 0 // Start DMA Transfer On Channel
    sta.w REG_MDMAEN     // $420B: DMA Enable
    nop

    rts
}

scope ClearOAM: {
    constant OAMEntries(128)
    constant OAMPerLoop(8)
    ldy.w # OAMEntries / OAMPerLoop
    ldx.w #0
-
    lda.b #$e0
    evaluate i(OAMPerLoop - 1)
    while {i} >= 0 {
        sta.w mem.OAMBuffer + 1 + 4*{i},x
        evaluate i({i} - 1)
    }
    rep #$21
    txa
    adc.w # 4 * OAMPerLoop
    tax
    sep #$20
    dey
    bne -

    rts
}

scope BuildOAM: {
    scope vars {
        constant Accum(0)
        constant Count(1)
    }

    sep #$30
    ldx.b #$00
    txy
-
    lda.b #$04
    sta.b vars.Count
-
    lda.w mem.OAMBufferHigh,x
    ror
    ror.b vars.Accum
    ror
    ror.b vars.Accum
    inx
    dec.b vars.Count
    bne -
    lda.b vars.Accum
    sta.w mem.OAMBufferHighComp,y
    iny
    cpy.b #$20
    bne --
    rep #$10
    rts
}

scope UploadFromGfxBuffer: {
    scope vars {
        constant InVramDest(0)
        constant InSize(2)
    }
    lda.b #$80                  // Set Increment VRAM Address After Accessing Hi Byte
    sta.w REG_VMAIN             // $2115: Video Port Control
    ldx.w vars.InVramDest       // Set VRAM Destination
    stx.w REG_VMADDL            // $2116: VRAM

    lda.b #$01                  // Set DMA Mode (Write Word, Increment Source)
    sta.w REG_DMAP0             // $43X0: DMA Control
    lda.b #$18                  // Set Destination Register ($2118: VRAM Write)
    sta.w REG_BBAD0             // $43X1: DMA Destination
    ldx.w #mem.GfxOutBuf        // Set Source Offset
    stx.w REG_A1T0L             // $43X2: DMA Source
    lda.b #mem.GfxOutBuf >> 16  // Set Source Bank
    sta.w REG_A1B0              // $43X4: Source Bank
    ldx.w vars.InSize           // Set Size In Bytes To DMA Transfer
    stx.w REG_DAS0L             // $43X5: DMA Transfer Size/HDMA

    lda.b #$01                  // Start DMA Transfer On Channel
    sta.w REG_MDMAEN            // $420B: DMA Enable

    rts
}

scope Expand2BPPTo4BPP: {
    scope vars {
        constant InPtr(0)
        constant InTileCount(2)
        constant InColor(3)

        constant Color1(4)
        constant Color2(5)
        constant Temp(6)
    }

    sep #$30
    lda.b vars.InColor
    ror                         // rotate bottom bit into carry
    pha
    jsr ExpandCarryInA
    sta.b vars.Color1
    pla
    ror                         // rotate orig. 2nd bottom bit into carry
    jsr ExpandCarryInA
    sta.b vars.Color2

    rep #$10
    ldx.w #$0000
    ldy.w #$0000
-
	lda.b (vars.InPtr),y
	iny
	sta.l mem.GfxOutBuf,x
	sta.b vars.Temp
	lda.b (vars.InPtr),y
	iny
	sta.l mem.GfxOutBuf+1,x
	ora.b vars.Temp
	sta.b vars.Temp
	and.b vars.Color1
	sta.l mem.GfxOutBuf+16,x
	lda.b vars.Temp
	and.b vars.Color2
	sta.l mem.GfxOutBuf+16+1,x
	inx
	inx
	cpx.w #16
	bcc -
	rep #$21
	txa
	adc.w #16
	tax
	lda.b vars.InPtr
	adc.w #16
	sta.b vars.InPtr
	sep #$20
	dec.b vars.InTileCount
	bne -
    // no regs saved, MX = 2
	rts

ExpandCarryInA:
    lda.b #$00
    sbc.b #$00                  // a = carry ? 0 : ff
    eor.b #$ff                  // negate a
    // end result: a = carry ? ff : 0
    rts
}
