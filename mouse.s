;------------------------------------------------------------------------------
; Function......: mouse_scan
; Purpose.......: Gets mouse state; changes color of item if mouse is
;                 hovering above it; runs the item if mouse is clicked
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc mouse_scan
    ;Get mouse state
    ldx #$24            ;Mouse state data saved in $24-$27
    jsr MOUSE_GET
    sta button_state

    ;Convert x/y coordinates to program item number
    stz index

    ldx #3              ;Mouse X/8
:   lsr $25
    ror $24
    dex
    bne :-

    ldx #3              ;Mouse Y/8
:   lsr $27
    ror $26
    dex
    bne :-

    lda $24             
    cmp #5              ;Mouse left of all items
    bcc mouse_out
    cmp #35
    bcc check_y         ;Mouse may be over items in the left column
    cmp #45
    bcc mouse_out       ;Mouse is in between items
    cmp #75
    bcs mouse_out       ;Mouse is to the right of all items

    lda #1              ;Add 1 to index for items in right column
    sta index

check_y:
    lda $26
    cmp #20
    bcc mouse_out       ;Mouse is above all items

    sec
    sbc #20

    and #%00000011
    cmp #%00000011
    beq mouse_out       ;Mouse is at empty line between items

    sec                 ;Calculate index           
    lda $26
    and #%11111100
    sbc #20
    lsr
    clc
    adc index
    sta index

check_available:
    ina
    cmp file_appcount
    beq mouse_over
    bcs mouse_out

mouse_over:
    ldx mouse_over_item
    cpx #$ff
    beq :+

    ldy #0                      ;Reset previously hovered item
    jsr screen_item_on_mouse

:   ldx index
    stx mouse_over_item
    ldy #1
    jsr screen_item_on_mouse    ;Change color indicating we're hovering over item

check_button:
    lda button_state
    and #%00000001
    beq :+
    ldx index
    jsr file_run

:   rts

mouse_out:
    ldx mouse_over_item
    cpx #$ff
    beq :+

    ldy #0                      ;Reset previously hovered item
    jsr screen_item_on_mouse
    lda #$ff
    sta mouse_over_item

:   rts

.segment "GOLDENRAM"
    index: .res 1
    button_state: .res 1
.CODE
.endproc

.segment "GOLDENRAM"
    mouse_over_item: .res 1
.CODE