*
bigdisplay
        jsr countbit    ; count 1 bits for this part
        lda counter     ; words found for this part total = 0 ?
        ora counter+1
        ora counter+2
        bne go          ; no : go on
        rts

go      lda #3          ; start display on line # 4
        jsr vtab
*** WORDS file
        lda #'L'        ; set file name for MLI open call
        sta fname+1
        ldx pattern
        lda tohex,x 
        sta fname+2
        lda #'/'
        sta fname+3
        lda #$03
        clc
        adc words       ; add length of "WORDS"
        sta fname
        ldx words       ; x = length of "WORDS"
copyfn  lda words,x 
        sta fname+3,x   ; copy "WORDS" at the end of file name 
        dex
        bne copyfn

        lda #$00        ; set buffer for WORDS files : $8800
        sta fbuff
        lda #$88
        sta fbuff+1
        jsr MLI         ; open WORDS file
        dfb open
        da  c8_parms
        bcc savref
        jmp ko 

savref  lda ref
        sta refword     ; save ref ID of WORDS file.

*** process index 
        lda #>bitmap1   ; set pointer to $2000 area
        sta ptr1+1
        lda #<bitmap1
        sta ptr1

loopreadbyte
        ldy #$00
        lda (ptr1),y    ; get byte to process
        sta tempo
        bne nonzero
        jmp zerobyte

nonzero ldy #$08
        sty savebit 
dolsr   lsr tempo
        bcs bitfound

nextbit 
        jsr incwrdcnt   ; word counter++
        dec savebit     ; dec number of bits to scan
        bne dolsr       ; not 8 bits yet : loop
* inc ptr
        jmp eoword3     ; update pointers for next byte 

bitfound
*** set_mark call
        ldx #$02
copywc  lda wordscnt,x  ; copy word counter to filepos param for set_mark call param
        sta filepos,x 
        dex
        bpl copywc
        ldx #$04
mul16wc asl filepos     ; filepos = filepos * 16 (16 char per word in words file)
        rol filepos+1
        rol filepos+2
        dex
        bne mul16wc 

        lda refword     ; copy file ID from open call 
        sta refce       ; to set-mark call param
        sta refread     ; and to read call param
        jsr MLI         ; set_mark call
        dfb setmark
        da ce_param
        bcc readw 
        jmp ko
*** read a word
readw   lda #reclength
        sta rreq        ; 16 bytes to read
        lda #$00
        sta rreq+1    
        lda #<rdbuff    ; set data buffer for reading file
        sta rdbuffa
        lda #>rdbuff+1
        sta rdbuffa+1       
        jsr MLI         ; load word
        dfb read
        da  ca_parms
        bcc prnres
        jmp ko

*** print word
prnres
        jsr result      ; print word read in word file
        inc displayed   ; # of word displayed ++
        lda displayed
        cmp #90         ; = 90 words ?
        bne godisp      ; no : kepp on displying words
        lda #0          ; yes : reset displayed to 0
        sta displayed   ; save it
        cr
        cr
        prnstr presskeylib
        jsr dowait      ; wait for a key pressed
        cmp #$9b        ; escape ?
        bne newscreen   ; no : go on
        tsx             ; yes : reset stack (+2)
        inx             ; to avoid stack overflow
        inx 
        txs 
        jmp init        ; and go to beginning of program
newscreen
        jsr home        ; clear screen
godisp
        lda col         ; adjust position on screen for next word
        cmp #64         ; 64 horizontal = last posiotn on line           
        beq lastcol     
        clc             ; enough room opu next word 
        adc #16         ; move horizontal posiiton 16 rows to the right 
        jmp outscr
lastcol                 
        lda displayed   ; if displayed = 0 (beginning of screen) then non cr
        beq nocr 
        cr              ; last horizontal posiiton on screen
nocr
        lda #$00        ; reset horizontal posiiton    
outscr  sta col         ; store in col var
        sta ourch       ; set value for rom/prodos routine

eoword  
        jsr incwrdcnt
        dec savebit 
        beq lsrok
        jmp dolsr
lsrok   jmp eoword3
*** end of LSR loop 

eoword3       
        inc ptr1
        bne noinc2
        inc ptr1+1
noinc2  
        lda ptr1+1
        cmp #$20 + #$20
        beq dispexit
doloop  jmp loopreadbyte

dispexit 
        lda #$00
        sta $BF94
        closef #$00      
        jsr FREEBUFR    ; free all buffers
        rts
zerobyte
        lda wordscnt    ; word counter : +8
        clc
        adc #$08
        sta wordscnt
        lda #$00
        adc wordscnt+1
        sta wordscnt+1
        lda #$00
        adc wordscnt+2
        sta wordscnt+2
        jmp eoword3     ; next byte

************** end of displayw **************
***
incwrdcnt 
        inc wordscnt    ; inc word counter
        bne nowinc1
        inc wordscnt+1
nowinc1 bne incfin
        inc wordscnt+2
incfin  rts
