.include "common.inc"
.include "kernal.inc"

.segment "CODE"

main:
    ;Setup
    stz exitflag                ;0=continue running
    stz kb_prevkey
    stz file_appcount           ;Number of programs
    lda #$ff
    sta file_hiddencount        ;Number of hidden programs
    lda #$ff                    ;ff=mouse isn't over any item
    sta mouse_cur_index
    stz mouse_not_hover_count
    jsr screen_init             ;Print greeting
    jsr irq_init                ;Init IRQ, used for VBLANK

    ;Wait 2.5 seconds
    ldx #150
:   jsr irq_wait_vblank
    dex
    bne :-

    ;Greetings are displayed at middle of screen, scroll upward once per VBLANK
    ldx #21
:   phx
    jsr irq_wait_vblank
    jsr screen_scroll
    plx
    dex
    bne :-

    ;Read application information from config file and output to screen
    jsr screen_print_all

    ;Enable mouse
    ldx #80
    ldy #60
    lda #1
    jsr MOUSE_CONFIG

    ;Init joystick
    jsr joystick_init

    ;Select first item on startup, if available
    ldx #0
    cpx file_appcount
    beq :+
    stx joystick_cur_index
    ldy #1
    jsr screen_set_item_color

    ;Init scrolling message
:   jsr message_init

    ;Main loop
main_loop:
    jsr irq_wait_vblank
    jsr message_scroll
    jsr joystick_scan
    jsr kb_scan
    jsr mouse_scan
    lda exitflag
    beq main_loop

    ;Reset IRQ handler
    jsr irq_reset

    ;Disable mouse
    lda #0
    jsr MOUSE_CONFIG

    ;Exit to basic
    rts

.segment "GOLDENRAM"
    exitflag: .res 1
.CODE


.include "screen.s"
.include "irq.s"
.include "file.s"
.include "kb.s"
.include "mouse.s"
.include "joystick.s"
.include "charset.s"
.include "message.s"