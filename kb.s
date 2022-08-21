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
    cmp #65
    bcc exit
    cmp #91
    bcs exit

    ;Convert to program index, A being index 0
    sec
    sbc #65
    cmp file_appcount   ;check if index+1 <= program count
    bcs exit

run:
    tax
    jsr file_run

exit:
    rts
.endproc