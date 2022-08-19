;------------------------------------------------------------------------------
; Function......: screen_init
; Purpose.......: Setup screen
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc screen_init
    ;Clear screen
    lda #147
    jsr $ffd2

    ;Print X16 logo
    lda #20
    sta VERA_ADDRL
    lda #$b0+26
    sta VERA_ADDRM
    lda #%00010001
    sta VERA_ADDRH

    ldx #7          ;7 lines
    ldy #0
print_x16logo:
    lda x16logo,y
    beq next_x16logo
    sta VERA_DAT
    iny
    bra print_x16logo

next_x16logo:
    iny
    lda #20
    sta VERA_ADDRL
    inc VERA_ADDRM
    dex
    bne print_x16logo

    ;Print VCF MW17
    lda #42
    sta VERA_ADDRL
    lda #$b0+26
    sta VERA_ADDRM
    lda #%00100001
    sta VERA_ADDRH

    ldx #7  ;7 lines to print
    ldy #0
    lda #<vcfmw17
    sta $22
    lda #>vcfmw17
    sta $23
print_vcfmw17:
    lda ($22),y
    beq next_vcfmw17
    cmp #'x'
    bne :+
    lda #81
:   sta VERA_DAT
    iny
    bne print_vcfmw17
    inc $23
    bra print_vcfmw17

next_vcfmw17:
    iny
    lda #42
    sta VERA_ADDRL
    inc VERA_ADDRM
    dex
    bne print_vcfmw17
    
    rts

x16logo:
    .byt 223, 100, 32, 100, 32, 100, 32, 100, 32, 100, 32, 100, 233, 100, 0
    .byt 244, 110, 223, 110, 32, 110, 32, 110, 32, 110, 233, 110, 231, 110, 0
    .byt 245, 99, 160, 99, 223, 99, 32, 99, 233, 99, 160, 99, 246, 99, 0
    .byt 32, 101, 119, 101, 251, 101, 32, 101, 236, 101, 119, 101, 32, 97, 0
    .byt 32, 103, 111, 103, 254, 103, 32, 103, 252, 103, 111, 103, 32, 97, 0
    .byt 103, 104, 160, 104, 105, 104, 32, 104, 95, 104, 160, 104, 116, 104, 0
    .byt 118, 98, 105, 98, 32, 98, 32, 98, 32, 98, 95, 98, 117, 98, 0

vcfmw17:
    .byt " xxx     x   x  xxx  xxxx   x    x x    x  x xxxx",0
    .byt "x   x    x   x x   x x      xx  xx x    x xx    x",0
    .byt "x x x    x   x x     x      x xx x x    x  x    x",0
    .byt "x xxx    x   x x     xxx    x xx x x    x  x   x ",0 
    .byt "x        x   x x     x      x    x x xx x  x   x ",0
    .byt "x   x     x x  x   x x      x    x x xx x  x   x ",0
    .byt " xxx       x    xxx  x      x    x  x  x  xxx  x ",0

.endproc

;------------------------------------------------------------------------------
; Function......: screen_scroll
; Purpose.......: Scrolls screen upwards one step per invokation
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc screen_scroll
    stz VERA_ADDRL
    lda #$b0+1
    sta VERA_ADDRM
    lda #%00000001
    sta VERA_ADDRH

    ldx #160
loop:
    lda VERA_DAT
    dec VERA_ADDRM
    sta VERA_DAT
    inc VERA_ADDRM
    
    inc VERA_ADDRL
    dex
    bne loop

    inc VERA_ADDRM
    lda VERA_ADDRM
    cmp #$b0+34
    beq :+
    stz VERA_ADDRL
    bra loop

:   rts
.endproc

;------------------------------------------------------------------------------
; Function......: screen_print_all
; Purpose.......: Gets info about all programs from the config file and
;                 prints to the screen
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc screen_print_all
    jsr file_open_config

:   jsr file_get_appinfo
    bcs :+
    bne :+
    ldx file_appcount
    jsr screen_print_appinfo
    inc file_appcount
    bra :-

:   jsr file_close_config
    rts
.endproc

;------------------------------------------------------------------------------
; Function......: screen_print_appinfo
; Purpose.......: Prints info about one program to the screen
; Prep..........: Call file_get_app_info which reads the info into a RAM buffer
; Input.........: X = application number
; Output........: None
;------------------------------------------------------------------------------
.proc screen_print_appinfo
    ;Setup
    stx index

    ;Check left or right column
    txa
    lsr
    bcs right

left:
    lda #10
    sta xaddr
    bra row

right:
    lda #90
    sta xaddr

row:
    txa
    lsr
    asl
    asl
    clc
    adc #$b0+20
    sta yaddr

    lda xaddr
    ina
    sta VERA_ADDRL
    lda yaddr
    sta VERA_ADDRM
    lda #%00000001
    sta VERA_ADDRH

    stz field

    ldy #0
println:
    lda xaddr
    ina
    sta VERA_ADDRL
    lda #%00000001
    sta VERA_ADDRH
    
    lda #80                 ;Default color setting
    sta VERA_DAT
    
    clc
    lda xaddr
    adc #4
    sta VERA_ADDRL
    lda #%00100001
    sta VERA_ADDRH

:   lda file_cur_app,y
    beq :+
    jsr screen_to_scrcode
    sta VERA_DAT
    iny
    bra :-

:   inc VERA_ADDRM
    iny
    inc field
    lda field
    cmp #3
    bne println

    lda xaddr
    sta VERA_ADDRL
    lda yaddr
    ina
    sta VERA_ADDRM
    clc
    lda index
    adc #65
    jsr screen_to_scrcode
    sta VERA_DAT

    rts

.segment "GOLDENRAM"
    xaddr: .res 1
    yaddr: .res 1
    field: .res 1
    index: .res 1
.CODE
.endproc

;x=item
;y: 1 = over, 1 = out
;------------------------------------------------------------------------------
; Function......: screen_item_on_mouse
; Purpose.......: Changes color of vertical band at left side of item
;                 depending on whether the mouse is hovering over it
;                 or not
; Input.........: X = program index
;                 Y : 0 = mouse out
;                     1 = mouse over
; Output........: None
;------------------------------------------------------------------------------
.proc screen_item_on_mouse
    txa
    and #%00000001
    beq left

right:
    lda #91
    sta VERA_ADDRL
    bra row

left:
    lda #11
    sta VERA_ADDRL

row:
    txa
    and #%11111110
    asl
    clc
    adc #$b0+20
    sta VERA_ADDRM

high:
    lda #%10010001
    sta VERA_ADDRH

    cpy #0
    beq mouse_out

mouse_over:
    lda #64
    bra set_color

mouse_out:
    lda #80

set_color:
    sta VERA_DAT
    sta VERA_DAT
    sta VERA_DAT
    rts

.endproc

;------------------------------------------------------------------------------
; Function......: screen_to_scrcode
; Purpose.......: Converts PETSCII to screen code
; Input.........: A = PETSCII code
; Output........: A = screen code
;------------------------------------------------------------------------------
.proc screen_to_scrcode
    cmp #32
    bcs :+
    clc
    adc #128
    rts

:   cmp #64
    bcs :+
    rts

:   cmp #96
    bcs :+
    sec
    sbc #64
    rts

:   cmp #128
    bcs :+
    sec
    sbc #32
    rts

:   cmp #160
    bcs :+
    clc
    adc #64
    rts

:   cmp #192
    bcs :+
    sec
    sbc #64
    rts

:   sbc #255
    bne :+
    sec
    sbc #128
    rts

:   lda #94
    rts
.endproc