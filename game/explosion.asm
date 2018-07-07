scope explosion {
    constant HandlerL(handlers.HandlerL)
    constant HandlerS(handlers.HandlerS)
    scope handlers {
        scope vars {
        }
    HandlerL:
        //pea routines.DrawLarge
        bra routines.HandlerCommon
    HandlerS:
        //pea routines.DrawSmall
        bra routines.HandlerCommon
    }

    scope routines {
        scope vars {
            constant CurrentIndex(0)
            constant ObjX(2)
            constant ObjY(4)
            constant ObjAnimState(6)
            constant OAMNum(14)

            constant XOffset(8)
            constant YOffset(9)
            constant TileIndex(10)
            constant TileNum(12)
            constant YCache(13)
            constant FlagCache(7)
        }
    HandlerCommon:
        // check collision
        rts

    DrawLarge:
        sep #$30
        lda.b vars.ObjAnimState
        tax                     // for later
        asl
        asl
        asl
        clc
        adc.b vars.ObjAnimState
        sta.b vars.TileIndex     // TileIndex = ObjAnimState * 9
        stz.b vars.TileIndex+1   // it's used in 16-bit mode, so upper byte needs to be 0

        lda.w data.Flags,x
        sta.b vars.FlagCache

        rep #$30
        lda.b vars.OAMNum
        tay
        asl
        asl
        tax
        sep #$20
        lda.b #$00
        sta.b vars.YOffset
    YLoop:
        rep #$21
        and.w #$00ff
        adc.b vars.ObjY
        cmp.w # consts.ScreenHPx
        bpl OffBottom
        cmp.w # -15
        sep #$20
        bpl DontSkipLine
        lda.b #$e0
    DontSkipLine:
        sta.b vars.YCache
        lda.b #$00
        sta.b vars.XOffset
    XLoop:
        rep #$21                // 16 bit + clc
        and.w #$00ff
        adc.b vars.ObjX
        cmp.w # consts.ScreenWPx
        bpl TileOffScreen
        cmp.w # -15
        sep #$20
        bmi TileOffScreen
        sta.w mem.OAMBuffer,x
        lda.b vars.YCache
        sta.w mem.OAMBuffer+1,x
        phy
        ldy.b vars.TileIndex
        lda.w data.LargeTileNumbers,y
        ply
        sta.w mem.OAMBuffer+2,x
        lda.b vars.FlagCache
        sta.w mem.OAMBuffer+3,x
        xba
        and.b #$01
        ora.b #$02
        sta.w mem.OAMBufferHigh,y
        //bra TileNotOffScreen
    TileOffScreen:
        sep #$20
    TileNotOffScreen:
        iny
        inx
        inx
        inx
        inx
        inc.b vars.TileIndex
        lda.b #$10
        clc
        adc.b vars.XOffset
        sta.b vars.XOffset
        cmp.b #$30
        bmi XLoop
        lda.b #$10
        clc
        adc.b vars.YOffset
        sta.b vars.YOffset
        cmp.b #$30
        bmi YLoop
    OffBottom:
        sep #$20
        sty.b vars.OAMNum
        rts
    }




    scope data {
        LargeTileNumbers:
            db $00,$02,$04,$20,$22,$24,$40,$42,$44
            db $06,$08,$0a,$26,$28,$2a,$46,$48,$4a
            db $60,$62,$64,$80,$82,$84,$a0,$a2,$a4
            db $66,$68,$6a,$86,$88,$8a,$a6,$a8,$aa
            db $64,$62,$60,$84,$82,$80,$a4,$a2,$a0
            db $0a,$08,$06,$2a,$28,$26,$4a,$48,$46
        Flags:
            db $00,$00,$00,$00,$40,$40
    }
}