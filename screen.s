;------------------------------------------------------------------------------
; Function......: screen_init
; Purpose.......: Setup screen
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc screen_init
    lda #$ff
    sta screen_header_flash_row
    
    ;Clear screen
    lda #147
    jsr $ffd2

    ;Print X16 logo
    lda #10
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
    lda #10
    sta VERA_ADDRL
    inc VERA_ADDRM
    dex
    bne print_x16logo

    ;Print VCF MW17
    lda #32                         ;Column 16
    sta VERA_ADDRL
    lda #$b0+26                     ;Line 26
    sta VERA_ADDRM
    lda #%00010001                  ;Auto-increment 1
    sta VERA_ADDRH

    ldx #7                          ;7 lines to print
    lda #<vcfmw17
    sta $22
    lda #>vcfmw17
    sta $23
    ldy #0
print_vcfmw17:
    lda ($22),y                     ;Get pixel data
    beq next_vcfmw17
    pha
    lda #81                         ;PETSCII - filled circle
    sta VERA_DAT
    pla
    cmp #'x'
    bne :+
    lda #97                         ;White foreground, blue background (active)
    bra :++
:   lda #96+11                      ;Dark grey foreground, blue background (inactive)
:   sta VERA_DAT
    iny
    bne print_vcfmw17
    inc $23
    bra print_vcfmw17

next_vcfmw17:
    iny
    lda #32                         ;Column 16
    sta VERA_ADDRL
    inc VERA_ADDRM                  ;Next row
    dex                             ;Decrease line counter, exit if 0
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
    .byt " xxx     x   x  xxx  xxxx   x    x x    x  x xxxx    ",0
    .byt "x   x    x   x x   x x      xx  xx x    x xx    x    ",0
    .byt "x x x    x   x x     x      x xx x x    x  x    x    ",0
    .byt "x xxx    x   x x     xxx    x xx x x    x  x   x     ",0 
    .byt "x        x   x x     x      x    x x xx x  x   x     ",0
    .byt "x   x     x x  x   x x      x    x x xx x  x   x     ",0
    .byt " xxx       x    xxx  x      x    x  x  x  xxx  x     ",0

.endproc

;------------------------------------------------------------------------------
; Function......: screen_scroll
; Purpose.......: Scrolls screen upwards one step per invokation
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc screen_scroll
    stz VERA_ADDRL      ;4
    lda #$b0+1          ;2
    sta VERA_ADDRM      ;4
    lda #%00000001      ;2
    sta VERA_ADDRH      ;4

    ldx #160            ;2
loop:
    lda VERA_DAT        ;4
    dec VERA_ADDRM      ;6
    sta VERA_DAT        ;4
    inc VERA_ADDRM      ;6
    
    inc VERA_ADDRL      ;6
    dex                 ;2
    bne loop

    inc VERA_ADDRM      ;6
    lda VERA_ADDRM      ;4
    cmp #$b0+34         ;2
    beq :+              ;2
    stz VERA_ADDRL      ;4
    bra loop            ;3 = 49 cycles x 160 = 7,840 cycles = 980 us @ 8 MHz 

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
    bcs eof

    ldx file_hiddencount
    cpx #$ff
    beq :+
    inc file_hiddencount
    bra :-

:   ldx file_appcount
    jsr screen_print_appinfo
    inc file_appcount
    bra :--

eof:
    jsr file_close_config
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
    and #%11111110
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
    
    lda #91                 ;Default color setting
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

;------------------------------------------------------------------------------
; Function......: screen_set_item_color
; Purpose.......: Changes color of vertical band at left side of item
; Input.........: X = program index
;                 Y : 0 = set color for mouse not hovering
;                     1 = set color for mouse hovering
; Output........: None
;------------------------------------------------------------------------------
.proc screen_set_item_color
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
    lda #75
    bra set_color

mouse_out:
    lda #91

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

:   cmp #255
    beq :+
    sec
    sbc #128
    rts

:   lda #94
    rts
.endproc

.segment "GOLDENRAM"
    screen_header_flash_row: .res 1
.CODE

