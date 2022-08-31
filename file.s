;-----------------------------------------------------------------------------
; Function......: file_open_config
; Purpose.......: Opens the config file for reading
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc file_open_config
    ;Copy config file name to RAM
    ldy #0
:   lda configfile,y
    beq :+
    sta file_buffer,y
    iny
    bra :-

    ;Open config file
:   tya
    ldx #<file_buffer
    ldy #>file_buffer
    jsr SETNAM

    lda #1
    ldx #8
    ldy #0
    jsr SETLFS

    lda #1
    jsr OPEN

    ldx #1
    jsr CHKIN
    
    rts

configfile:
    .byt "x16kiosk.txt",0
.endproc

;------------------------------------------------------------------------------
; Function......: file_get_appinfo
; Purpose.......: Loads information about the next application from
;                 a config file ("//:x16kiosk.txt")
; Input.........: None
; Output........: C = 1, if incomplete app info (EOF)
;                 Application information is stored in the file_cur_app
;                 RAM buffer as five null terminated strings in the
;                 following order:
;                 1. Application display name
;                 2. Short description
;                 3. Author
;                 4. Application folder
;                 5. Application file name
;------------------------------------------------------------------------------
.proc file_get_appinfo
    ;Setup
    stz field
    stz index_in
    stz index_out
    stz st

readln:
    lda st
    bne eof
    
    jsr CHRIN
    sta char
    jsr READST
    sta st
    and #255-64
    bne eof         ;Other problem than EOF marker
    lda char
    cmp #10         ;LF
    beq eol
    cmp #13         ;CR
    beq eol
    ldy index_in
    sta file_buffer,y
    inc index_in
    bra readln

eol:
    ldy index_in
    beq readln                  ;Skip empty line

    lda file_buffer
    cmp #'#'
    bne :+
    stz index_in
    bra readln                  ;Skip line starting with #

:   cmp #'*'
    bne :++
    lda file_hiddencount
    cmp #$ff
    bne :+
    inc file_hiddencount
:   stz index_in
    bra readln

:   ldy #0                      ;Copy field to app info buffer
    ldx index_out
:   lda file_buffer,y
    sta file_cur_app,x
    iny
    inx
    cpy index_in
    bne :-

    stz index_in
    
    lda #0
    sta file_cur_app,x
    inx
    stx index_out

    lda field
    cmp #4
    beq done
    inc field
    bra readln

done:
    clc
    rts

eof:
    sec
    rts

.segment "GOLDENRAM"
    char: .res 1
    index_in: .res 1
    index_out: .res 1
    field: .res 1
    st: .res 1
.CODE
.endproc

;------------------------------------------------------------------------------
; Function......: file_close_config
; Purpose.......: Closes the config file
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc file_close_config
    lda #1
    jsr CLOSE
    jsr CLRCHN
    rts
.endproc

;------------------------------------------------------------------------------
; Function......: file_run
; Purpose.......: Changes the current directory to the one used by the program,
;                 and then loads and runs the specified program
; Input.........: X = Index of program to start
; Output........: None
;------------------------------------------------------------------------------
.proc file_run
    txa
    stx index
    
    jsr file_open_config
:   jsr file_get_appinfo
    ldx index
    beq :+
    dec index
    bra :-
:   jsr file_close_config

ch_dir:
    ldx #0
    ldy #0
:   lda file_cur_app,y
    beq :+
    iny
    bra :-

:   iny
    inx
    cpx #3
    bne :--

    lda #'c'
    sta file_buffer
    lda #'d'
    sta file_buffer+1
    
    ldx #0
:   lda file_cur_app,y
    beq :+
    sta file_buffer+2,x
    iny
    inx
    bra :-

:   iny
    phy

    txa
    clc
    adc #2
    ldx #<file_buffer
    ldy #>file_buffer
    jsr SETNAM

    lda #15
    ldx #8
    ldy #15
    jsr SETLFS

    lda #15
    jsr OPEN

    lda #15
    jsr CLOSE

run:
    ply
    ldx #0
:   lda file_cur_app,y
    beq :+
    sta file_buffer,x
    inx
    iny
    bra :-

:   txa
    ldx #<file_buffer
    ldy #>file_buffer
    jsr SETNAM

    lda #0
    ldx #8
    ldy #1
    jsr SETLFS

    lda #0
    jsr LOAD

    lda #0
    jsr CLOSE
    
    inc exitflag            ;Set exitflag to exit from main loop
    
    rts

.segment "GOLDENRAM"
    index: .res 1
.CODE
.endproc

.segment "GOLDENRAM"
    file_cur_app: .res 256
    file_buffer: .res 256
    file_appcount: .res 1
    file_hiddencount: .res 1
.CODE