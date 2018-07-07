scope objects {
    scope Process: {
        
    Start:
        sep #$30
        stz.b mem.ObjTmp.CurrentIndex
        ldx.b #$00
        stz.b mem.ObjTmp.OAMNum
        stz.b mem.ObjTmp.OAMNum+1

    Loop:
        // Check if object is active
        lda.b mem.Objects.Type,x
        sta.b mem.ObjTmp.ObjType
        bpl ObjActive
        brl ObjInactive

    ObjActive:
        // Calculate word offset for data tables
        // (This is based on object index)
        txy
        txa
        asl
        tax

        // Load object state
        lda.w mem.Objects.State,y
        sta.b mem.ObjTmp.ObjState

        // Use 16-bit math for position, simplifies things
        rep #$20
        // Update object position
        lda.w mem.Objects.VX,y
        and.w #$00ff
        adc.b mem.Objects.X,x
        sta.b mem.Objects.X,x
        jsr.w tools.S16DivBy8
        sta.b mem.ObjTmp.ObjX
        
        lda.w mem.Objects.VY,y
        and.w #$00ff
        adc.b mem.Objects.Y,x
        sta.b mem.Objects.Y,x
        jsr.w tools.S16DivBy8
        sta.b mem.ObjTmp.ObjY

        // Get byte and word offsets based on ObjType
        ldy.b mem.ObjTmp.ObjType
        tya
        asl
        tax

        // Check if object is on screen
        lda.b mem.ObjTmp.ObjY
        cmp.w # consts.ScreenHPx
        bpl ObjNotOnScreen
        cmp.w data.ObjectHeightsForBounds,x
        bmi ObjNotOnScreen

        lda.b mem.ObjTmp.ObjX
        cmp.w # consts.ScreenWPx
        bpl ObjNotOnScreen
        cmp.w data.ObjectWidthsForBounds,x
        bmi ObjNotOnScreen

        // Done dealing with position, back to 8-bit accum
        sep #$20

        // Load object dimensions
        lda.w data.ObjectWidths,y
        sta.b mem.ObjTmp.ObjW
        lda.w data.ObjectHeights,y
        sta.b mem.ObjTmp.ObjH

        // Call object-specific handler
        jsr (data.ObjectHandlers,x)

        // Save new state
        ldx.b mem.ObjTmp.CurrentIndex
        lda.b mem.ObjTmp.ObjState
        sta.b mem.Objects.State,x

        bra ObjHandled

    ObjNotOnScreen:
        // Disable object
        sep #$20
        lda.b #$ff
        ldx.b mem.ObjTmp.CurrentIndex
        sta.b mem.Objects.Type,x

    ObjHandled:
    ObjInactive:
        inx
        cpx.b # consts.NumObjects
        beq End
        stx.b mem.ObjTmp.CurrentIndex
        brl Loop
    End:
        rep #$10
        sep #$20
        rts

        scope data {
            ObjectWidths:
                db consts.CoinLW,consts.CoinMW,consts.CoinSW
                db consts.ExplosionLW,consts.ExplosionSW
            ObjectHeights:
                db consts.CoinLH,consts.CoinMH,consts.CoinSH
                db consts.ExplosionLH,consts.ExplosionSH
            ObjectWidthsForBounds:
                dw -(consts.CoinLW-1),-(consts.CoinMW-1),-(consts.CoinSW-1)
                dw -(consts.ExplosionLW-1),-(consts.ExplosionSW-1)
            ObjectHeightsForBounds:
                dw -(consts.CoinLH-1),-(consts.CoinMH-1),-(consts.CoinSH-1)
                dw -(consts.ExplosionLH-1),-(consts.ExplosionSH-1)
            ObjectHandlers:
                dw coin.HandlerL,coin.HandlerM,coin.HandlerS
                dw explosion.HandlerL,explosion.HandlerS
        }
    }
}
