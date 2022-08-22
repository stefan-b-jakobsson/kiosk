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

    ;Check if mouse position or button status has changed
    ldx #0
:   lda $24,x
    cmp mouse_old_state,x
    bne :+
    inx
    cpx #5
    bne :-

    lda button_state
    bne :+
    rts

    ldx #0
:   lda $24,x
    sta mouse_old_state,x
    inx
    cpx #5
    bne :-

    jsr joystick_unselect

    ;Convert x/y coordinates to program index
    stz new_index

    ldx #3              ;Mouse X/8 and Mouse Y/8
:   lsr $25
    ror $24
    lsr $27
    ror $26
    dex
    bne :-

    lda $24             
    cmp #5              ;Mouse left of all items
    bcc mouse_out
    cmp #35
    bcc check_y         ;Mouse may be hovering over items in the left column
    cmp #45
    bcc mouse_out       ;Mouse is in between left and right column of items
    cmp #75
    bcs mouse_out       ;Mouse is to the right of all items

    lda #1              ;Add 1 to index for items in right column
    sta new_index

check_y:
    sec
    lda $26
    sbc #20
    bcc mouse_out       ;Mouse is above all items

    and #%00000011
    cmp #%00000011
    beq mouse_out       ;Mouse is at empty line between items

    sec                 ;Calculate index
    lda $26
    and #%11111100
    sbc #20
    lsr
    clc
    adc new_index
    sta new_index

check_available:
    cmp file_appcount
    bcs mouse_out

mouse_over:
    ldx mouse_cur_index
    cpx #$ff
    beq :+

    ldy #0                      ;Reset previously hovered item
    jsr screen_set_item_color

:   ldx new_index
    stx mouse_cur_index
    ldy #1
    jsr screen_set_item_color    ;Change color indicating we're hovering over item

check_button:
    lda button_state
    and #%00000001
    beq :+
    ldx new_index
    jsr file_run

:   rts

mouse_out:
    ldx mouse_cur_index
    cpx #$ff
    beq :+

    ldy #0                      ;Reset previously hovered item
    jsr screen_set_item_color
    lda #$ff
    sta mouse_cur_index

:   rts

.segment "GOLDENRAM"
    new_index: .res 1
    button_state: .res 1
.CODE
.endproc

;------------------------------------------------------------------------------
; Function......: mouse_unselect
; Purpose.......: Unselects previously hovered item
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc mouse_unselect
    ldx mouse_cur_index
    cpx #$ff
    beq :+
    ldy #0
    jsr screen_set_item_color
    ldx #$ff
    stx mouse_cur_index
:   rts
.endproc

.segment "GOLDENRAM"
    mouse_cur_index: .res 1
    mouse_old_state: .res 5
.CODE