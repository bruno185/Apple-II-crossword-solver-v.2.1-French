* v2.1.1 french
* the number of bytes to be analyzed is reduced to the number of bytes in the index file.
*<sym>
bigdisplay
        jsr countbit    ; count 1 bits 
        lda counter     ; words found total = 0 ?
        ora counter+1
        ora counter+2
        bne go          ; no : go on
        rts
*<sym>
go      lda #3          ; start display on line # 4
        jsr vtab
*** WORDS file
        lda #'L'        ; set file name for MLI open call
        sta fname+1
        ldx pattern     ; get word length, file path = L + pattern length (in hex format) / WORDS
        lda tohex,x 
        sta fname+2
        lda #'/'
        sta fname+3
        lda #$03
        clc
        adc words       ; add length of "WORDS"
        sta fname
        ldx words       ; x = length of "WORDS"
*<sym>
copyfn  lda words,x 
        sta fname+3,x   ; copy "WORDS" at the end of file path  
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

*<sym>
savref  lda ref
        sta refword     ; save ref ID of WORDS file.

*** process index 
        lda #>bitmap1   ; set pointer to $2000 area
        sta ptr1+1
        lda #<bitmap1
        sta ptr1

*<sym>
loopreadbyte
        ;jsr setmax      ; v2.1.1 : set maximum adresse of last byte to analyse (= $2000 + filelength)
        ; no longer needed, as setmex is already called in the countbit function  
        ; at the beginning of bigdisplay.  
        ldy #$00
        lda (ptr1),y    ; get byte to process
        sta tempo
        bne nonzero     
        jmp zerobyte    ; if byte = 0, just add 8 to counter (8 bits are 0)

*<sym>
nonzero ldy #$08        ; else : find bit set to 1 and load corresponding word in WORDS file
        sty savebit 
*<sym>
dolsr   lsr tempo       ; get bit in carry
        bcs bitfound    ; if bit = 1

*<sym>
nextbit                 ; bit = 0
        jsr incwrdcnt   ; word counter++
        dec savebit     ; dec number of bits to scan
        bne dolsr       ; not 8 bits yet : loop
* inc ptr
        jmp eoword3     ; byte is finished : update pointers for next byte 

*<sym>
bitfound
* current bit = 1 : find the corresionding word
* 
*** set_mark call
* 
        ldx #$02
*<sym>
copywc  lda wordscnt,x  ; copy word counter to filepos param for set_mark call param
        sta filepos,x 
        dex
        bpl copywc
        ldx #$04
*<sym>
mul16wc asl filepos     ; file offset = filepos * 16 (16 char per word in words file)
        rol filepos+1
        rol filepos+2
        dex
        bne mul16wc     ; multiply by 2, 4 times => multiply by 16. 
                        ; because each word takes 16 bytes in words file.

        lda refword     ; copy file ID from open call 
        sta refce       ; to set-mark call param
        sta refread     ; and to read call param
        jsr MLI         ; set_mark call
        dfb setmark
        da ce_param
        bcc readw 
        jmp ko
*** read a word
*<sym>
readw   lda #reclength  ; read word file to get current matching word
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
*<sym>
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
*<sym>
newscreen
        jsr home        ; clear screen
*<sym>
godisp
        lda col         ; adjust position on screen for next word
        cmp #64         ; 64 horizontal = last posiotn on line           
        beq lastcol     
        clc             ; enough room opu next word 
        adc #16         ; move horizontal posiiton 16 rows to the right 
        jmp outscr
*<sym>
lastcol                 
        lda displayed   ; if displayed = 0 (beginning of screen) then non cr
        beq nocr 
        cr              ; last horizontal posiiton on screen
*<sym>
nocr
        lda #$00        ; reset horizontal posiiton   
*<sym> 
outscr  sta col         ; store in col var
        sta ourch       ; set value for rom/prodos routine

*<sym>
eoword  
        jsr incwrdcnt   ; update word counter
        dec savebit     ; update bit counter   
        beq eoword3     ; if 0 : next byte
        jmp dolsr       ; if <> 0 loop to get next bit

*** end of LSR loop 

*<sym>
eoword3       
        inc ptr1                ; inc. pointer to next byte to analyse
        bne noinc2
        inc ptr1+1
*<sym>
noinc2 
                                ; v2.1.1 french
        lda ptr1+1              ; compare it to adress of last byte to analyse
        cmp max+1
        bne doloop              ; non equal : loop
        lda ptr1
        cmp max
        bne doloop              ; non equal : loop
        beq dispexit            ; equal : exit
*<sym>
doloop  jmp loopreadbyte

*<sym>
dispexit 
        lda #$00                ; exit of bigdisplay routine
        sta $BF94
        closef #$00      
        jsr FREEBUFR    ; free all buffers
        rts
*<sym>
zerobyte
                        ; here byte = 0 
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
*<sym>
setmax                  ; set adress of last byte to analyse
        lda filelength  ; get file length (of index file)
        sta max         ; set max (low byte)
        lda filelength+1        ; get hi byte
        clc
        adc #$20        ; add it to starting adress of memory
        sta max+1
        rts
*<sym>

incwrdcnt 
        inc wordscnt    ; inc word counter
        bne nowinc1
        inc wordscnt+1
*<sym>
nowinc1 bne incfin
        inc wordscnt+2
*<sym>
incfin  rts
