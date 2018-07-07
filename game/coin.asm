scope coin {
    constant HandlerL(handlers.HandlerL)
    constant HandlerM(handlers.HandlerM)
    constant HandlerS(handlers.HandlerS)
    scope handlers {
        scope vars {
        }
    HandlerL:
        // We push the address of the routine that we want to call
        //   so that when HandlerCommon returns, it runs the Draw routine
        // We need the -1 because ???? the 6502 be like that
        pea routines.DrawLarge - 1
        bra routines.HandlerCommon
    HandlerM:
        pea routines.DrawMedium - 1
        bra routines.HandlerCommon
    HandlerS:
        pea routines.DrawSmall - 1
        bra routines.HandlerCommon
    }
    scope routines {
        scope vars {
            StartVariables(mem.ObjTmp.Tmp)
            Variable(XOffset,1)
            Variable(YOffset,1)
            Variable(TileCache,0) // union
            Variable(TileIndex,2)
            Variable(TileNum,1)
            Variable(YCache,1)
            Variable(FlagCache,1)
            EndVariables()
        }
    HandlerCommon:
        // check collision

        // gravity
        ldx.b mem.ObjTmp.CurrentIndex
        lda.b mem.Objects.VY,x
        clc
        adc.b #$01
        cmp.b #$60
        bpl +
        sta.b mem.Objects.VY,x
    +
        rts

        scope DrawLarge: {
            sep #$30
            lda.b mem.ObjTmp.ObjState
            inc
            cmp.b # $08 * 6
            bcc +
            lda.b #$00
        +
            sta.b mem.ObjTmp.ObjState
            
            lsr
            lsr
            lsr
            sta.b vars.TileIndex    // no point in using a temp variable
            tax                     // for later
            asl
            asl
            asl
            clc
            adc.b vars.TileIndex
            sta.b vars.TileIndex     // TileIndex = (ObjState >> 3) * 9
            stz.b vars.TileIndex+1   // it's used in 16-bit mode, so upper byte needs to be 0

            lda.w data.Flags,x
            sta.b vars.FlagCache

            rep #$30
            lda.b mem.ObjTmp.OAMNum
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
            adc.b mem.ObjTmp.ObjY
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
            adc.b mem.ObjTmp.ObjX
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
            sty.b mem.ObjTmp.OAMNum
            sep #$30
            rts
        }

        // TODO: refactor and deduplicate this code!!!!
        // Actually, maybe that's a premature optimization.
        // I don't think this code will change, so there's no need to refactor for easier changes
        // Space probably won't be an issue unless we try uploading it
        scope DrawMedium: {
            sep #$30
            lda.b mem.ObjTmp.ObjState
            inc
            cmp.b # $08 * 6
            bcc +
            lda.b #$00
        +
            sta.b mem.ObjTmp.ObjState
            
            lsr
            lsr
            lsr
            tax                     // for later
            asl
            asl
            sta.b vars.TileIndex     // TileIndex = (ObjState >> 3) * 4
            stz.b vars.TileIndex+1   // it's used in 16-bit mode, so upper byte needs to be 0

            lda.w data.Flags,x
            sta.b vars.FlagCache

            rep #$30
            lda.b mem.ObjTmp.OAMNum
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
            adc.b mem.ObjTmp.ObjY
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
            adc.b mem.ObjTmp.ObjX
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
            lda.w data.MediumTileNumbers,y
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
            cmp.b #$20
            bmi XLoop
            lda.b #$10
            clc
            adc.b vars.YOffset
            sta.b vars.YOffset
            cmp.b #$20
            bmi YLoop
        OffBottom:
            sty.b mem.ObjTmp.OAMNum
            sep #$30
            rts
        end:
        print "\nDrawMedium length: 0x"
        evaluate length(end - DrawMedium)
        hexprint({length})
        print "\n"
        }

        scope DrawSmall: {
            sep #$30
            lda.b mem.ObjTmp.ObjState
            inc
            cmp.b # $08 * 6
            bcc +
            lda.b #$00
        +
            sta.b mem.ObjTmp.ObjState
            
            lsr
            lsr
            lsr
            tax                      // for later
            lda.w data.Flags,x
            sta.b vars.FlagCache
            lda.w data.SmallTileNumbers,x
            sta.b vars.TileCache

            rep #$30
            lda.b mem.ObjTmp.OAMNum
            tay
            asl
            asl
            tax
            lda.b mem.ObjTmp.ObjX
            sep #$20
            sta.w mem.OAMBuffer,x
            lda.b mem.ObjTmp.ObjY
            sta.w mem.OAMBuffer+1,x
            lda.b vars.TileCache
            sta.w mem.OAMBuffer+2,x
            lda.b vars.FlagCache
            sta.w mem.OAMBuffer+3,x
            xba
            and.b #$01
            ora.b #$02
            sta.w mem.OAMBufferHigh,y
            iny
            sty.b mem.ObjTmp.OAMNum
            sep #$30
            rts
        }
    }


    scope data {
        LargeTileNumbers:
            db $00,$02,$04,$20,$22,$24,$40,$42,$44
            db $06,$08,$0a,$26,$28,$2a,$46,$48,$4a
            db $60,$62,$64,$80,$82,$84,$a0,$a2,$a4
            db $66,$68,$6a,$86,$88,$8a,$a6,$a8,$aa
            db $64,$62,$60,$84,$82,$80,$a4,$a2,$a0
            db $0a,$08,$06,$2a,$28,$26,$4a,$48,$46
        MediumTileNumbers:
            db $0c,$0e,$2c,$2e
            db $4c,$4e,$6c,$6e
            db $8c,$8e,$ac,$ae
            db $cc,$ce,$ec,$ee
            db $8e,$8c,$ae,$ac
            db $4e,$4c,$6e,$6c
        SmallTileNumbers:
            db $c0
            db $c2
            db $c4
            db $c6
            db $c4
            db $c2
        Flags:
            db $00,$00,$00,$00,$40,$40
    }
}
