;BUILD: cl65 -v -o AUTOBOOT.X16 -t cx16 -u __EXEHDR__ -C cx16-asm.cfg -vm autoboot.s

KBDBUF_PUT = $fec3
GETIN = $ffe4

init:
    lda #147
    jsr $ffd2

    ;Copy launch code
    ldx #0
:   lda starter,x
    sta $0400,x
    inx
    cpx #starter_end-starter
    bne :-
    
    ;Clear keyboard buffer
    sei
:   jsr GETIN
    bne :-

    ;Insert SYS command to start menu program
    ldx #0
:   lda sys,x
    beq :+
    jsr KBDBUF_PUT
    inx
    bra :-

:   cli
    rts

starter:
    lda #9
    sta 1
    jsr $c000

    lda #4
    sta 1
    rts
starter_end:

sys:
    .byt "sys$0400",13,0