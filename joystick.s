;------------------------------------------------------------------------------
; Function......: joystick_init
; Purpose.......: Initializes joystick functions
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc joystick_init
    ;Set values
    lda #$ff
    sta joystick_cur_index
    sta joystick_old_state
    sta joystick_old_state+1

    ;Find first available joystick
    lda #1
    sta joystick_device
:   lda joystick_device
    cmp #5
    bcs no_joystick
    jsr JOYSTICK_GET
    cpy #$00
    beq joy_found
    inc joystick_device
    bra :-

joy_found:
    rts

no_joystick:
    stz joystick_device     ;use keyboard instead of joystick
    rts
.endproc

;------------------------------------------------------------------------------
; Function......: joystick_scan
; Purpose.......: Gets current joystick state
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc joystick_scan
    lda joystick_device
    jsr JOYSTICK_GET
    cpy #$00
    beq :+
    jmp joystick_init       ;Previously found joystick no longer responds; could this happen?
    
:   sta joystick_new_state
    txa
    sta joystick_new_state+1

    lda joystick_new_state
    and #%00000001
    bne :+
    jmp right

:   lda joystick_new_state
    and #%00000010
    bne :+
    jmp left

:   lda joystick_new_state
    and #%00000100
    bne :+
    jmp down

:   lda joystick_new_state
    and #%00001000 
    bne :+
    jmp up

:   txa
    and #%10000000
    bne :+
    jmp a_pressed

:   jmp update_old_state

right:
    lda joystick_new_state
    ora joystick_old_state
    and #%00000001
    bne :+
    jmp update_old_state

:   jsr mouse_unselect

    ldx joystick_cur_index
    cpx #$ff
    beq :+
    ldy #0
    jsr screen_set_item_color
    
:   inc joystick_cur_index
    ldx joystick_cur_index
    cpx file_appcount
    bcc :+
    stz joystick_cur_index
    ldx #0

:   ldy #1
    jsr screen_set_item_color
    jmp update_old_state

left:
    lda joystick_new_state
    ora joystick_old_state
    and #%00000010
    bne :+
    jmp update_old_state

:   jsr mouse_unselect

    ldx joystick_cur_index
    cpx #$ff
    beq :+
    ldy #0
    jsr screen_set_item_color

:   dec joystick_cur_index
    ldx joystick_cur_index
    cpx #$ff
    bne :+
    ldx file_appcount
    dex
    stx joystick_cur_index

:   ldy #1
    jsr screen_set_item_color
    jmp update_old_state

down:
    lda joystick_new_state
    ora joystick_old_state
    and #%00000100
    beq update_old_state

    jsr mouse_unselect

    ldx joystick_cur_index
    cpx #$ff
    bne :+
    ldx #0
    bra :++

:   ldy #0
    jsr screen_set_item_color

:   inx
    cpx file_appcount
    bcc :+
    ldx #0
    bra :++

:   inx
    cpx file_appcount
    bcc :+
    dex

:   stx joystick_cur_index
    ldy #1
    jsr screen_set_item_color
    jmp update_old_state

up:
    lda joystick_new_state
    ora joystick_old_state
    and #%00001000
    beq update_old_state

    jsr mouse_unselect

    ldx joystick_cur_index
    cpx #$ff
    bne :+
    ldx #0
    bra :+++

:   ldy #0
    jsr screen_set_item_color

    dex
    cpx #$ff
    bne :+
    ldx file_appcount
    dex
    bra :++

:   dex
    cpx #$ff
    bne :+
    ldx #0

:   stx joystick_cur_index
    ldy #1
    jsr screen_set_item_color
    jmp update_old_state

a_pressed:
    ldx joystick_cur_index
    cpx #$ff
    beq update_old_state
    inc exitflag
    jsr file_run

update_old_state:
    lda joystick_new_state
    ldx joystick_new_state+1

    sta joystick_old_state
    stx joystick_old_state+1
    rts

.segment "GOLDENRAM"
    joystick_new_state: .res 2
.CODE
.endproc
;------------------------------------------------------------------------------
; Function......: joystick_unselect
; Purpose.......: Unselects an item previously selected by the joystick
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc joystick_unselect
    ldx joystick_cur_index
    cpx #$ff
    beq :+
    ldy #0
    jsr screen_set_item_color
    ldx #$ff
    stx joystick_cur_index
:   rts
.endproc

.segment "GOLDENRAM"
    joystick_device: .res 1
    joystick_cur_index: .res 1
    joystick_old_state: .res 2
.CODE