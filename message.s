;------------------------------------------------------------------------------
; Function......: message_init
; Purpose.......: Inits the scrolling billboard message
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc message_init
    jsr message_from_file
    
    ;Setup pointer to start of text
    lda #$00
    sta message_pointer
    lda #$a0
    sta message_pointer+1

    lda #$01        ;Select RAM bank 1
    sta $00
    
    ;Init delay counter
    lda #2
    sta message_delay
    stz message_delay+1

    ;Ensure hold is not armed
    stz message_hold_arm

    rts
.endproc

;------------------------------------------------------------------------------
; Function......: message_from_file
; Purpose.......: Reads text message from file into RAM buffer
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc message_from_file
    ;Setup pointer to start of RAM
    lda #$00
    sta message_pointer
    lda #$a0
    sta message_pointer+1

    lda #$01        ;Select RAM bank 1
    sta $00
    
    ;Copy file name to RAM
    ldy #0
:   lda fname,y
    beq :+
    sta file_buffer,y
    iny
    bra :-

    ;Open file
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
    
    ;Read file content
    stz st
loop:
    lda st
    bne eof
    jsr CHRIN
    sta char
    jsr READST
    sta st
    and #255-64
    bne eof
    lda char
    sta (message_pointer)
    inc message_pointer
    bne loop
    inc message_pointer+1
    bra loop

eof:
    lda #0
    sta (message_pointer)

close:
    lda #1
    jsr CLOSE
    jsr CLRCHN
    rts

    fname:
        .byt "kioskmsg.txt",0
    
    .segment "GOLDENRAM"
        st: .res 1
        char: .res 1
    .CODE
.endproc

;------------------------------------------------------------------------------
; Function......: message_scroll
; Purpose.......: Scrolls the message one step left. If at character boundary,
;                 fetches the next character from the message
; Input.........: None
; Output........: None
;------------------------------------------------------------------------------
.proc message_scroll
    ;Check delay counters
    dec message_delay
    beq :+
    rts

:   lda message_delay+1
    beq :+
    dec message_delay+1
    rts

    ;Reset delay counter
:   lda #2
    sta message_delay

    ;Hold
    lda message_hold_arm
    beq :+
    dec message_hold_arm
    bne :+

    ;Set delay
    lda #<1800
    sta message_delay
    lda #>1800
    sta message_delay+1
    rts

    ;Scroll already printed pixels one step left
:   lda #$b0+5          ;Line 5
    sta VERA_ADDRM
    lda #%00000001      ;No auto-increment
    sta VERA_ADDRH

:   ldx #35             ;Source column color
    stx VERA_ADDRL
    ldy #33             ;Destination column color

:   lda VERA_DAT        ;Get source color
    sty VERA_ADDRL      
    sta VERA_DAT        ;Set destination color
    txa                 ;Destination=source
    tay
    inx                 ;Source+=2
    inx
    stx VERA_ADDRL
    cpx #139            ;Are we done with this line?
    bcc :-  

    inc VERA_ADDRM      ;Select next line
    lda VERA_ADDRM
    cmp #$b0+13         ;Are we done with all lines?
    bne :--             ;No, start over with next line

    ;At character boundary?
    lda message_curchar+7
    bne :+
    
    jsr message_fetch_char
    cmp #104            ;Hold control char?
    bne :+
    jsr message_fetch_char
    lda #53             ;Hold will start after 50 invokations
    sta message_hold_arm

:   lda #137            ;Select rightmost column color setting
    sta VERA_ADDRL
    lda #$b0+5          ;Line 5
    sta VERA_ADDRM
    lda #%10010001      ;Auto-increment +256
    sta VERA_ADDRH

    ;Output one column of pixels of next char    
    ldx #0
loop:
    asl message_curchar,x   ;Shift next pixel to carry
    bcc :+
    lda #97                 ;97 = White foreground + blue background (active state)
    bra :++
:   lda #96+11              ;Dark grey foreground + blue background (inactive state)
:   sta VERA_DAT
    inx                     ;Next line
    cpx #7                  ;Are we done?
    bne loop

    ;Decrease pixel column
    dec message_curchar+7

    rts
.endproc

;------------------------------------------------------------------------------
; Function......: message_fetch_char
; Purpose.......: Gets next character from the message string. Wraps around to
;                 the first character if finding a 0 (NULL) value
; Input.........: None
; Output........: A = next character index
;------------------------------------------------------------------------------
.proc message_fetch_char
    ;Get next character
    lda (message_pointer)
    tax                                 ;Store char index in X
    beq wraparound                      ;NULL => wraparound to start of text

    jsr screen_to_scrcode               ;Convert PETSCII to screen code
    
    ;Calculate pointer to character definition
    sta message_charpointer
    stz message_charpointer+1
    asl message_charpointer
    rol message_charpointer+1
    asl message_charpointer
    rol message_charpointer+1
    asl message_charpointer
    rol message_charpointer+1
    clc
    lda message_charpointer
    adc #<charset_def
    sta message_charpointer
    lda message_charpointer+1
    adc #>charset_def
    sta message_charpointer+1

    ;Read char data into RAM array (8 bytes)
    ldy #0
:   lda (message_charpointer),y
    sta message_curchar,y
    iny
    cpy #8
    bne :-

    ;Increase pointer to message text
    inc message_pointer
    bne :+
    inc message_pointer+1
:   txa                             ;Retrieve char index from X
    rts

wraparound:
    lda #$00
    sta message_pointer
    lda #$a0
    sta message_pointer+1
    bra message_fetch_char
.endproc

message_pointer = $28
message_charpointer = $2a

.segment "GOLDENRAM"
    message_curchar: .res 8
    message_hold_arm: .res 1
    message_hold_delay: .res 1
    message_delay: .res 2
.CODE