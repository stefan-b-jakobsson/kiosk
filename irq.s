;------------------------------------------------------------------------------
; Function......: irq_init
; Purpose.......: Initializes custom IRQ handler
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc irq_init
    ;Copy custom IRQ handler to golden RAM
    ldy #0
:   lda irq_handler,y
    sta irq_handler_ram,y
    iny
    cpy #15     ;Length of IRQ handler
    bne :-

    ;Change IRQ vector
    sei
    
    lda $0314
    sta irq_default
    lda $0315
    sta irq_default+1

    lda #<irq_handler_ram
    sta $0314
    lda #>irq_handler_ram
    sta $0315

    cli
    rts
.endproc

;------------------------------------------------------------------------------
; Function......: irq_handler
; Purpose.......: Custom IRQ handler
; Input.........: None
; Output........: Sets the programs own irq_vblank flag
;------------------------------------------------------------------------------
.proc irq_handler
    lda $9f27
    and #%00000001
    beq :+
    lda #%00000001
    sta irq_vblank
:   jmp (irq_default)
.endproc

;------------------------------------------------------------------------------
; Function......: irq_wait_vblank
; Purpose.......: Waits for VBLANK
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc irq_wait_vblank
    lda irq_vblank
    lsr
    bcc irq_wait_vblank
    stz irq_vblank
    rts
.endproc

.segment "GOLDENRAM"
    irq_handler_ram: .res 15
    irq_default: .res 2
    irq_vblank: .res 1
.CODE