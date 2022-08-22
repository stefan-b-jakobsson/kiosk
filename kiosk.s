.include "common.inc"
.include "kernal.inc"

.segment "CODE"

main:
    ;Setup
    stz file_appcount           ;Number of programs
    stz exitflag                ;0=continue running
    lda #$ff                    ;ff=mouse isn't over any item
    sta mouse_cur_index
    jsr screen_init             ;Print greeting
    jsr irq_init                ;Init IRQ, used for VBLANK

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

    ;Main loop
:   jsr irq_wait_vblank
    jsr kb_scan
    jsr mouse_scan
    jsr joystick_scan
    lda exitflag
    beq :-

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