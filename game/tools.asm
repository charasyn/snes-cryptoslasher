scope tools {
S16DivBy8:
// Space: 1 + 4n bytes
// Time:  6 + 5n cycles
// i=5: 21 31
// i=6: 25 36
    evaluate i(5)
    while {i} > 0 {
        cmp.w #$8000
        ror
        evaluate i({i} - 1)
    }
    rts

S16DivBy8HardcodedSinglePath:
// Space: 11 + n bytes
// Time:  19 + 2n cycles (+ve)
//        21 + 2n cycles (-ve)
// i=5: 16 31
// i=6: 17 33
    ora.w # 0
    php
    evaluate i(5)
    while {i} > 0 {
        lsr
        evaluate i({i} - 1)
    }
    plp
    bpl +
    ora.w #$e000
+
    rts

S16DivBy32:
    evaluate n(5)
    ora.w # 0
    bmi +
// -ve
    evaluate i({n})
    while {i} > 0 {
        lsr
        evaluate i({i} - 1)
    }
    rts
+
    evaluate i({n})
    while {i} > 0 {
        lsr
        evaluate i({i} - 1)
    }
    ora.w #$e000
    rts
// Space: 10 + 2n bytes
// Time:  11 + 2n cycles (+ve)
//        15 + 2n cycles (-ve)
// i=5: 20 25
// i=6: 22 27

}
