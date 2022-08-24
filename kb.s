;------------------------------------------------------------------------------
; Function......: kb_scan
; Purpose.......: Gets next key from keyboard buffer; runs a possible
;                 program connected to the key
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc kb_scan
    ;Scan keyboard
    jsr GETIN
    pha
    beq exit

    cmp #91
    bcs exit

    ;Check hidden programs (0-9)
    ldx kb_prevkey
    cpx #'.'
    bne :+
    cmp #'0'
    bcc exit
    cmp #'9'+1
    bcs :+

    sec
    sbc #48
    cmp file_hiddencount
    bcs exit

    clc
    adc file_appcount
    tax
    jsr file_run
    bra exit

    ;Convert to program index, A being index 0
:   sec
    sbc #65
    bcc exit

    cmp file_appcount   ;check if index+1 <= program count
    bcs exit

run:
    tax
    jsr file_run

exit:
    pla                 ;Get char from stack
    beq :+
    sta kb_prevkey
:   rts
.endproc

.segment "GOLDENRAM"
    kb_prevkey: .res 1
.CODE