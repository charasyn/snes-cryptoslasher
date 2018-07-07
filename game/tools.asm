scope tools {
S16DivBy8:
// Space: 1 + 4n bytes
// Time:  6 + 5n cycles
    evaluate i(3)
    while {i} > 0 {
        cmp.w #$8000
        ror
        evaluate i({i} - 1)
    }
    rts

S16DivBy8HardcodedSinglePath:
// Space: 11 + n bytes
// Time:  19 + 2n bytes (+ve)
//        21 + 2n bytes (-ve)
    ora.w # 0
    php
    lsr
    lsr
    lsr
    plp
    bpl +
    ora.w #$e000
+
    rts

S16DivBy8HardcodedBothPaths:
// Space: 10 + 2n bytes
// Time:  12 + 2n bytes (+ve)
//        14 + 2n bytes (-ve)
    ora.w # 0
    bpl +
// -ve
    asl
    asl
    asl
    ora.w #$e000
    rts
+
    asl
    asl
    asl
    rts
}

