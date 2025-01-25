************************
*   crossword solver   * 
************************
* \
* Purpose : make fast search in a 400000++  french words list, using patterns
* Uses special bitmap index files.
*
* History :
* version 1.0 : uses tempo files 
* version 1.1 : get rid of tempo files, works in memory mostly.
* version 1.2 : add a progress bar
* version 1.4 : 
* => new word file (ods8) 402328 words <= 15 chars, + 3 chars : AIRIAL, AIRIAUX, BRIC)
* => page stop (wait a key, or esc. to abort).
* version 2.0 : split dictionary and indexes by word length
* => now indexes don't need to be run length encoded, nor they need to be splited in 4 parts.

* version 2.1 french : 
* => now include Officiel du Scrabble 9 (2024) with new words. 
* NB : the 64 words deleted by the Scrabble editor (present in ODS8) have been reinstated.
* => minor optimisation
* => debug info for Applewin debugger.
* => better comments
*
********************  memory org.  ***********************
* Dictionary : 407192 words (402328 words in ODS8)
* ==> split in 14 parts, by number of letters (from 2 to 15)

* program : $1000 to $1FFF 
* bitmap1 : $2000 -> $3FFF  
* bitmap2 : $4000 -> $5FFF
* buffers for OPEN MLI call (1024 bytes) : $8400 (index files) and $8800 (words files) 
*
********************  main program  ***********************

* MLI calls (ProDOS)
MLI             equ $BF00
create          equ $C0
destroy         equ $C1
online          equ $C5
getprefix       equ $c7
setprefix       equ $c6
open            equ $C8
close           equ $CC
read            equ $CA
write           equ $CB
setmark         equ $ce
geteof          equ $d1 
quit            equ $65
*
* ProDOS
GETBUFR         equ $bef5
FREEBUFR        equ $BEF8 
devnum          equ $BF30   ; last used device here, format : DSSS0000 
RSHIMEM         equ $BEFB
*
* ROM routines
home            equ $FC58
text            equ $FB2F
;cout            equ $FDF0
cout            equ $FDED
vtab            equ $FC22
getln           equ $FD6A
getlnz          equ $FD67       ; = return + getln
getln1          equ $FD6F       ; = getln without prompt 
bascalc         equ $FBC1
crout           equ $FD8E     ; print carriage return 
clreop          equ $FC42     ; clear from cursor to end of page
clreol          equ $FC9C     ; clear from cursor to end of line
xtohex          equ $F944
rdkey           equ $FD0C     ; wait for keypress
printhex        equ $FDDA
AUXMOV          equ $C311
OUTPORT         equ $FE95
*
* ROM switches
RAMWRTOFF       equ $C004       ; write to main
RAMWRTON        equ $C005       ; write to aux
RAMRDON         equ $C003       ; read aux 
RAMRDOFF        equ $C002       ; read main
ALTCHARSET0FF   equ $C00E 
ALTCHARSET0N    equ $C00F
kbd             equ $C000
kbdstrb         equ $C010
col80off        equ $C00C
col80on         equ $C00D
80col           equ $C01F 	 
*
* page 0
cv              equ $25
ch              equ $24 
basl            equ $28
wndlft          equ $20
wndwdth         equ $21
wndtop          equ $22         ; Top Margin (0 - 23, 0 is default, 20 in graphics mode)
wndbtm          equ $23 
prompt          equ $33
*
ourch           equ $57B      ; Cursor's column position minus 1 (HTAB's place) in 80-column mode
ourcv           equ $5FB      ; 80 col vertical pos
*
****** FP routines ******
float   equ $E2F2       ; Converts SIGNED integer in A/Y (high/lo) into FAC 
PRNTFAC equ $ED2E       ; Prints number in FAC (in decimal format). FAC is destroyed
FIN     equ $EC4A       ; FAC = expression pointee par TXTPTR
FNEG    equ $EED0       ; FAC = - FAC
FABS    equ $EBAF       ; FAC = ABS(FAC)
F2INT16 equ $E752       ; FAC to 16 bits int in A/Y and $50/51 (low/high)
FADD    equ $E7BE       ; FAC = FAC + ARG 
FSUBT   equ $E7AA       ; FAC = FAC - ARG
FMULT   equ $E97F       ; Move the number pointed by Y,A into ARG and fall into FMULTT 
FMULTT  equ $E982       ; FAC = FAC x ARG
FDIVT   equ $EA69       ; FAC = FAC / ARG
RND     equ $EFAE       ; FAC = random number
FOUT    equ $ED34       ; Create a string at the start of the stack ($100−$110)
MOVAF   equ $EB63       ; Move FAC into ARG. On exit A=FACEXP and Z is set
CONINT  equ $E6FB       ; Convert FAC into a single byte number in X and FACLO
YTOFAC  equ $E301       ; Float y 
MOVMF   equ $EB2B       ; Routine to pack FP number. Address of destination must be in Y
                        ; (high) and X (low). Result is packed from FAC
QUINT   equ $EBF2       ; convert fac to 16bit INT at $A0 and $A1
STROUT  equ $DB3A       ; 
LINPRT  equ $ED24       ; Converts the unsigned hexadecimal number in X (low) and A (high) into a decimal number and displays it.
*
***********************    my equ  ***********************
bitmap1  equ $2000      ; $2000 -> $5FFF (bitmap index 1) => aux mem.
bitmap2  equ $4000      ; $6000 -> $9FFF (bitmap index 2) => aux mem.

ptr1     equ $06        ;
ptr2     equ $08
reclength equ $10       ; length of record in words file
pbline  equ $03         ; # of text line for progressbar
pbchar  equ #'-'        ; char for progressbar
pbora   equ #$80        ; char bit 7 for progressbar


********************************************************************
*                             P R O G R A M                        *
********************************************************************
        MX %11
        put mac.s
        org $1000

*<sym>
start   equ *

        jsr doprefix    ; set prefix
        cld
        jsr $C300       ; 80 col. (http://www.deater.net/weave/vmwprod/demos/sizecoding.html)

*<sym>
init   
        jsr text        ; init text mode, clear margins
        jsr home        ; clear screen + cursor to upper left corner
        printc titlelib ; display title of program
        cr              ; print return (macro)
        lda #$00
        sta $BF94
        closef #$00     ; close all files
        prnstr path     ; display prefix
        cr
        prnstr patternlib       ; print label 
        jsr mygetln     ; let user type pattern
        jsr testpat     ; test if letter(s) in pattern, set noletter var 
        lda quitflag    ; if ctrl-c or escape then quitflag > 0
        bne exit2       ; yes : exit program
        lda pattern     ; get pattern length
        cmp #$02        ; pattern length msut be >= 2
        bpl okpat
        cr
        prnstr kopatlib ; wrong pattern, message and loop
        jsr dowait      ; wait for a key pressed
        jmp init        ; goto beginning

*<sym>
exit2   rts             ; end of program
*<sym>
okpat   cr
        cr
*
********************  init vars **********************

        lda #$00        ; init. total counter (sum of counters for 4 parts, 3 bytes integer)
        
        sta wordscnt     ; init. word counter to 0 (3 bytes integer)
        sta wordscnt+1
        sta wordscnt+2

        sta col         ; init. horiz. position of resulting words 
        sta pbpos       ; init. progressbar in position 0
        sta displayed   ; 0 words displayed for now

        lda #4          ; set top margin to 4 
        sta wndtop


                        ; set progressbar division
                        ; divide #36 by word length
                        ; to set progressbar increment.
        lda pattern     ; get word length 
        sta draft       ; save it
        lda #$00 
        sta progdiv     ; init division = 0
        lda #36         ; 36 chars for index processing (= 72 chars in 80 col.)
*<sym>
dosub   inc progdiv     ; inc division
        sec
        sbc draft
        bpl dosub
        dec progdiv     ; adjut division

******************** main loop for searching words **********************
*<sym>
main    
        closef #$00     ; close all files
        jsr FREEBUFR    ; free all buffers 
        jsr bigloop     ; main program loop : porcess all letters of pattern
        jsr bigdisplay  ; prints found words 
        jsr progressbarfin      ; print last chars (-) of progressbar
        jsr showres     ; show final result (count)

*<sym>
eop     jsr dowait      ; wait for a pressed key 
        closef #$00     ; close all files 
        jsr FREEBUFR    ; free all buffers
        jmp init        ; loop to the beginning
******************** main program end ********************

*<sym>
progressbar             ; display a progreeebar while procesing index
        lda #pbline     ; get line # for progressbar
        jsr bascalc     ; get base address 
        lda pbpos       ; get last h position
        clc             ; add it to pointer
        adc basl
        sta basl
        lda #$00
        adc basl+1
        sta basl+1
        lda pbchar      ; get char to display in progressbar
        ora pbora       ; ora parameter char 
        ldy #$00        ; init loop counter
        sta $C000       ; 80store on
*<sym>
ploop
        sta RAMWRTON    ; write char in aux
        sta (basl),y 
        sta RAMWRTOFF
        sta (basl),y    ; write char in aux
        
        inc pbpos       ; update h position
        iny             ; inc counter
        cpy progdiv     ; test end of loop
        beq pbexit      ; end : exit
        jmp ploop       ; go on

*<sym>
pbexit  sta $C001       ; 80store off
        rts

*<sym>
progressbarfin          ; display last chars of progressbar while displaying found words
        lda #pbline     ; get line # for progressbar
        jsr bascalc     ; get base address 
        lda pbpos       ; get last h position
        clc             ; add it to pointer
        adc basl
        sta basl
        lda #$00
        adc basl+1
        sta basl+1
        lda pbchar      ; get char to display in progressbar
        ora pbora       ; ora parameter char 
        ldy #$00        ; init loop counter
        sta $C000       ; 80store on
*<sym>
ploop2
        sta RAMWRTON    ; write char in aux
        sta (basl),y 
        sta RAMWRTOFF
        sta (basl),y    ; write char in aux
        iny
        inc pbpos       ; update h position
        ldx pbpos
        cpx #40
        beq pbexit2     ; end : exit
        jmp ploop2      ; go on

*<sym>
pbexit2 sta $C001       ; 80store off
        rts

*************************************
*<sym>
bigloop lda #$01
        sta pos         ; position in pattern = 1
        clc
        jsr fillmem     ; fill bitmap1 ($2000-$3FFF) with $ff
                        ; fill bitmap2 ($4000-$5FFF) with $00

*<bp>
*<sym>
bigll   
        lda noletter    ; letter in pattern ?
        bne dolong      ; no : jump to length index process
                        ; yes : search (full process)
        ldx pos         ; x =  position in pattern
        dex             ; adjust (x must start from 0, pos start from 1)
        lda pattern+1,x ; get char from pattern
        cmp #'A'        ; char between A and  Z ? 
        bcc bloopnext   ; no : next char in pattern
        cmp #'Z'+1
        bcs bloopnext
        sta letter      ; yes : save char in letter var

        jsr interpret   ; set index file name, based on letter and position
        jsr dofile      ; process index file : load index file in main,
                        ; AND bitmap1 area and bitmap2 area, result in bitmap1 area
        jmp bloopnext

*<sym>
dolong  jsr dowlen      ; set index file name for length
        jsr dofile      ; process index file (just 1 file : "L")
        lda #36         ; 72 '-' to print
        sta progdiv
        jsr progressbar ; go print
        rts

*<sym>
bloopnext
        jsr progressbar
        inc pos         ; next char in pattern
        ldx pos
        dex             
        cpx pattern     ; end of pattern (1st char = length)
        bne bigll       ; no : loop
        rts
* end bigloop
*
*<sym>
dowlen                  ; Add criterion of word length by loading L index file 
                        ; Prepare file name 'Lx\L' where x is length of pattern (= length of words to find)
        lda #$4
        sta fname       ; file name is 6 char long
        lda #'L'        ; L folder
        sta fname+1
        ldx pattern     ; get pattern length
        lda tohex,x     ; to hex
        sta fname+2
        lda #'/'
        sta fname+3
        lda #'L'        ; L is first char of filename
        sta fname+4        
        rts
*
* show result of count
*<sym>
showres
        lda ourcv
        clc
        adc #$01
        sta cv
        sta ourcv 
        jsr vtab
        ;cr
        lda #$00
        sta ch
        sta ourch

        prnstr patlib   ; recall pattern
        prnstr pattern
        cr
        prnstr totallib ; print lib
        jsr print24bits ; print number of found words   
        rts             ; 
*
*<sym>
dofile
* process an index file : 
* - load it in bitmap2 area
* - AND bitmap1 and bitmap2 memory areas
*
* open index file
        jsr setopenbuffer       ; set buffer address
        jsr MLI                 ; OPEN file 
        dfb open
        da  c8_parms
        bcc ok1                 ; no error : go on
        ; else if index file is not found, it means there is no word matching pattern.
        ; so fill bitmap1 with 0
        lda #<bitmap1
        sta ptr1
        lda #>bitmap1
        sta ptr1+1
*<sym>
clearbmp1
        lda #0
        ldy #0
:1
        sta (ptr1),y            ; clear bitmap1
        iny 
        bne :1
        inc ptr1+1
        lda ptr1+1
        cmp #>bitmap2
        bne clearbmp1
        rts                     ; and return

*<sym>
ok1     
* get eof (to get file size)
        lda ref
        sta refd1
        jsr MLI                 ; get file length (set file length for next read MLI call)
        dfb geteof
        da d1_param
        bcc eofok
        jmp ko
*<sym>
eofok        
* read index file
        jsr readindex   ; prepare loading of index file (set ID, req. length, etc.)
        jsr MLI         ; load file in main memory
        dfb read
        da  ca_parms
        bcc okread
        jmp ko
*<sym>
okread  
        lda ref       ; close index file
        sta cc_parms+1
        jsr MLI
        dfb close
        da cc_parms
        bcc okclose
        jmp ko
*<sym>
okclose                 ; 
        sec 
        jsr doand2       ; AND $2000 and $4000 areas 
        rts
* end of dofile

*<sym>
setopenbuffer           ; set buffer to $8400 for OPEN mli call
        lda #$00
        sta fbuff
        lda #$84
        sta fbuff+1
        rts

* count bit set to 1 in index
*<sym>
countbit
        lda #>bitmap1   ; set pointer to $2000 area
        sta ptr1+1
        lda #<bitmap1
        sta ptr1
        
        lda #$00        ; init counter
        sta counter
        sta counter+1
        sta counter+2
*<sym>
loopcount
        ldy #$00
        lda (ptr1),y    ; get byte to read
        beq updateptr   ; byte = $00 : loop
        ldx #$08        ; 8 bits to check
*<sym>
shift   lsr
        bcc nocarry
        iny             ; y counts bits set to 1
*<sym>
nocarry dex
        bne shift       ; loop 8 times

        tya             ; number of bits in A
        beq updateptr   ; no bits to count
        clc             ; add bits to result (counter)
        adc counter
        sta counter
        lda #$00
        adc counter+1
        sta counter+1
        lda #$00
        adc counter+2 
        sta counter+2  
*<sym>     
updateptr    
        inc ptr1        ; next byte to read
        bne noincp1
        inc ptr1+1
*<sym>
noincp1
        lda ptr1+1
        cmp #$20+#$20        
        bne loopcount
        rts

******************* AND *******************

*<sym>
doand2                   ; AND bitmap1 and bitmap2 memory areas 
        lda #<bitmap1   ; set bitamp1 address in ptr1 
        sta ptr1
        lda #>bitmap1
        sta ptr1+1 
        lda #<bitmap2   ; set bitamp2 address in ptr2 
        sta ptr2
        lda #>bitmap2
        sta ptr2+1  
        ldy #$00
*<sym>
andloop2
        lda (ptr1),y    ; get byte from 1st area (bitmap1)
        and (ptr2),y    ; and bye from 2nd area (bitmap2)
        sta (ptr1),y    ; save result in 1st area (bitmap1)

        iny 
        bne andloop2

        inc ptr1+1
        inc ptr2+1

        ldx ptr1+1
        cpx #>bitmap2  ; ptr1 reached bitmap2
        bne andloop2
        rts

* NB : all "area" is ANDed ($2000 byte long). it is more 
* than actual index size (wich is obtained by get_eof in bigloop)
* TODO : test if a partial AND is faster

************** readindex **************
*<sym>
readindex               ; read index file 
        lda ref         ; get file ref id
        sta refread     ; set ref id for read mli call

        lda #<bitmap2   ; set buffer address
        sta rdbuffa
        lda #>bitmap2
        sta rdbuffa+1       

        lda filelength  ; set requested length (= length obtained by get_eof)
        sta rreq
        lda filelength+1
        sta rreq+1
        rts
*
*<sym>
mygetln                 ; to let user input pattern 
                        ; takes juste upper letters ans ?
                        ; ctrl-c or escape : exit
                        ; return : commit
                        ; delete : delete last char
        lda #$00
        sta pattern     ; pattern length = 0
        sta quitflag

*<sym>
readkeyboard
        lda kbd         ; key keystroke
        bpl readkeyboard
        cmp #$83        ; control-C ?
        bne glnsuite
*<sym>
quif    inc quitflag    ; yes : set quit flag to quit program
        jmp finpat
*<sym>
glnsuite
        cmp #$9b        ; escape ?
        beq quif
        cmp #$8D        ; return ? 
        beq finpat      ; yes : rts
        cmp #$ff        ; delete ? 
        beq delete
        cmp #$88        ; also delete
        beq delete
        and #$7F        ; clear bit 7 for comparisons
        cmp #'?'        ; ? is ok :  represents any char
        beq okchar
        cmp #'A'        ; char between A and  Z are ok
        bcc readkeyboard ; < A : loop
        cmp #'Z'+1
        bcc okchar      ; < Z+1, so char is between A and Z
        ; here if char > Z
        cmp #'a'                ; test for lowercase
        bcc readkeyboard        ; < a
        cmp #'z'+1
        bcs readkeyboard        ; > z
        and #%11011111

*<sym> 
okchar  
        ldy pattern     ; pattern must not exceed 15 chars 
        cpy #$0f 
        beq readkeyboard
        pha             ; save char
        ora #$80        ; print it
        jsr cout
        lda ourch       ; get horizontal position
        sta savech      ; save it
        inc pattern     ; pattern length ++
        pla             ; restore char
        ldx pattern     ; poke if in pattern string
        sta pattern,x 
        bit kbdstrb     ; clear kbd
        jmp readkeyboard        ; next char
; delete key
*<sym>
delete  lda pattern     ; get pattern length
        beq readkeyboard        ; if 0 just loop
        dec pattern     ; pattern lenth --
        lda savech      ; savech --
        dec
        sta ourch       ; update h position
        sta savech      ; save it 
        lda #' '        ; print space (to erase previous char)
        ora #$80
        jsr cout
        dec ourch       ; update ourch, so next char will be space was printed
        bit kbdstrb     ; and loop
        jmp readkeyboard

*<sym>
finpat  bit kbdstrb
        rts
**** end of mygetln 

*<sym>
testpat                 ; test if pattern only contains '?'
        ldx pattern
*<sym>
looptp  lda pattern,x ; get a char from pattern
        cmp #'?'
        bne letterfound ; a char is <> from '?'
        dex
        bne looptp
        lda #$01
        sta noletter    ; set flag 
        rts             ; all letters are '?'

*<sym>
letterfound             ; set flag and exit
        lda #$00
        sta noletter
        rts

*<m1>
*<sym>
noletter ds 1
*
*<sym>
fillmem
        lda #<bitmap1   ; set bitamp1 address in ptr2 (destination)
        sta ptr2
        lda #>bitmap1
        sta ptr2+1

        lda #$ff 
        ldy #$00
*<sym>
loopfm1
        sta (ptr2),y 
        iny
        bne loopfm1
        inc ptr2+1
        ldx ptr2+1
        cpx #$40
        bne loopfm1

        lda #<bitmap2   ; set bitamp1 address in ptr2 (destination)
        sta ptr2
        lda #>bitmap2
        sta ptr2+1

        lda #$00 
        ldy #$00
*<sym>
loopfm2
        sta (ptr2),y 
        iny
        bne loopfm2
        inc ptr2+1
        ldx ptr2+1
        cpx #$60
        bne loopfm2
        rts
*<sym>
interpret
* according to a letter and its position in word
* set the file name of the corresponding index
* file name format : L<length of word in hex>/<letter><position of letter(in hex)
        lda #'L'
        sta fname+1
        ldx pattern     ; get length of pattern
        lda tohex,x     ; transform in hex value
        sta fname+2
        lda #'/'
        sta fname+3

        lda letter      ; get letter
        sta fname+4     ; => first letter of file name
        ldx pos         ; get position of letter in mattern
        lda tohex,x     ; transform in hex value
        sta fname+5     

        lda #$05        ; set length of file name
        sta fname
        rts
*<sym>
print24bits
* prints 3 bytes integer in counter/counter+1/counter+2
* counter+2 must be positive

        lda counter+2        ; init fac with filelength+1/filelength+2
        ldy counter+1        ;
        jsr float               ; convert integer to fac
        jsr mult256             ; * 256
        lda counter          ; add filelength
        jsr dodadd
        jsr PRNTFAC
        rts
*<sym>
mult256
        ldy #>myfac
        ldx #<myfac
        jsr MOVMF       ; fac => memory (packed)
        lda #1
        ldy #0
        jsr float       ; fac = 256
        ldy #>myfac 
        lda #<myfac
        jsr FMULT       ; move number in memory (Y,A) to ARG and mult. result in fac
        rts
*<sym>
dodadd      
        pha 
        ldy #>myfac
        ldx #<myfac
        jsr MOVMF       ; fac => memory (packed)
        ply
        jsr YTOFAC
        ldy #>myfac 
        lda #<myfac
        jsr FADD        ; move number in memory (Y,A) to ARG and add. result in fac
        rts

*<sym>
result  ldx #$00                ; print data read in file (rdbuff = prameter of read mli call)
*<sym>
rslt    lda rdbuff,x
        beq finres              ; exit if char = 0
        ;ora #$80               ; inverse video 
        jsr cout
        inx 
        cpx #reclength          ; no more then record length
        bne rslt
*<sym>
finres  rts

*********** Error processing ***********
*<sym>
ko      pha             ; save error code
        prnstr kolib
        pla
        tax
        jsr xtohex
        cr
        rts

*********** Wait for a key ***********
*<sym>
dowait
        lda kbd
        bpl dowait
        bit kbdstrb
        rts
*
*********** PREFIX *************
*<sym>
doprefix
        jsr MLI           ; getprefix, prefix ==> "path"
        dfb getprefix
        da c7_param
        bcc suitegp
        jmp ko 

*<sym>
suitegp
        lda path        ; 1st char = length
        beq noprefix    ; if 0 => no prefix
        jmp good1       ; else prefix already set, exit 

*<sym>
noprefix
        lda devnum      ; last used slot/drive 
        sta unit        ; param du mli online
*<sym>
men     jsr MLI
        dfb online      ; on_line : get prefix in path
        da c5_param
        bcc suite
        jmp ko

*<sym>
suite   lda path
        and #$0f       ; length in low nibble
        sta path
        tax
*<sym>
l1      lda path,x
        sta path+1,x   ; offset 1 byte
        dex
        bne l1
        inc path
        inc path       ;length  +2
        ldx path
        lda #$af       ; = '/'
        sta path,x     ; / after
        sta path+1     ; and / before

        jsr MLI        ; set_prefix
        dfb setprefix
        da c6_param
        bcc good1
        jmp ko
*<sym>
good1   
        rts
*
        put bigdisplay.S

********************  disconnect /RAM  **********************
* from : https://prodos8.com/docs/techref/writing-a-prodos-system-program/
* biblio :
* https://www.brutaldeluxe.fr/products/france/psi/psi_systemeprodosdelappleii_ocr.pdf
* or SYSTEME PRODOS DE L'APPLE Il.pdf p.139.

*<sym>
devcnt equ $bf31        ; global page device count
*<sym>
devlst equ $bf32        ; global page device list
*<sym>
machid equ $bf98        ; global page machine id byte
*<sym>
ramslot equ $bf26       ; slot 3, drive 2 is /ram's driver vector in following list :

* ProDOS keeps a table of the addresses of the device drivers assigned to each slot and
* drive between $BF10 and $BF2F. There are two bytes for each slot and drive. $BF10-1F
* is for drive 1, and $BF20-2F is for drive 2. For example, the address of the device
* driver for slot 6 drive 1 is at $BF1C,1D. (Normally this address is $D000.)

*  BF10: Slot zero reserved
*  BF12: Slot 1, drive 1
*  BF14: Slot 2, drive 1
*  BF16: Slot 3, drive 1
*  BF18: Slot 4, drive 1
*  BF1A: Slot 5, drive 1
*  BF1C: Slot 6, drive 1
*  BF1E: Slot 7, drive 1
*  BF20: Slot zero reserved
*  BF22: Slot 1, drive 2
*  BF24: Slot 2, drive 2
*  BF26: Slot 3, drive 2 = I RAM, reserved
*  BF28: Slot 4, drive 2
*  BF2A: Slot 5, drive 2
*  BF2C: Slot 6, drive 2
*  BF2E: Slot 7, drive 2

 * nodev is the global page slot zero, drive 1 disk drive vector.
 * it is reserved for use as the "no device connected" vector.
 *<sym>
nodev equ $bf10
 *
 *<sym>
ramout
        php             ; save status and
        sei             ; make sure interrupts are off!
 *
 * first thing to do is to see if there is a /ram to disconnect!
 *
        lda machid      ; load the machine id byte
        and #$30        ; to check for a 128k system
        cmp #$30        ; is it 128k?
        bne done        ; if not then branch since no /ram!
 *
        lda ramslot     ; it is 128k; is a device there?
        cmp nodev       ; compare with low byte of nodev
        bne cont        ; branch if not equal, device is connected
        lda ramslot+1   ; check high byte for match
        cmp nodev+1     ; are we connected?
        beq done        ; branch, no work to do; device not there
 *
 * at this point /ram (or some other device) is connected in
 * the slot 3, drive 2 vector.  now we must go thru the device
 * list and find the slot 3, drive 2 unit number of /ram ($bf).
 * the actual unit numbers, (that is to say 'devices') that will
 * be removed will be $bf, $bb, $b7, $b3.  /ram's device number
 * is $bf.  thus this convention will allow other devices that
 * do not necessarily resemble (or in fact, are completely different
 * from) /ram to remain intact in the system.
 *
 *<sym>
cont ldy devcnt         ; get the number of devices online
*<sym>
loop lda devlst,y       ; start looking for /ram or facsimile
        and #$f3        ; looking for $bf, $bb, $b7, $b3
        cmp #$b3        ; is device number in {$bf,$bb,$b7,$b3}?
        beq found       ; branch if found..
        dey             ; otherwise check out the next unit #.
        bpl loop        ; branch unless you've run out of units.
        bmi done        ; since you have run out of units to
*<sym>
found lda devlst,y      ; get the original unit number back
        sta ramunitid   ; and save it off for later restoration.
 *
 * now we must remove the unit from the device list by bubbling
 * up the trailing units.
 *
 *<sym>
getloop 
        lda devlst+1,y  ; get the next unit number
        sta devlst,y    ; and move it up.
        beq exit        ; branch when done(zeros trail the devlst)
        iny             ; continue to the next unit number...
        bne getloop     ; branch always.
 *
 *<sym>
exit    lda ramslot     ; save slot 3, drive 2 device address.
        sta address     ; save off low byte of /ram driver address
        lda ramslot+1   ; save off high byte
        sta address+1   ;
 *
        lda nodev       ; finally copy the 'no device connected'
        sta ramslot     ; into the slot 3, drive 2 vector and
        lda nodev+1     
        sta ramslot+1   
        dec devcnt      ; decrement the device count.
 *
 *<sym>
done    plp             ; restore status
 *
        rts             ; and return
 *
 *<sym>
address dw $0000      ; store the device driver address here
*<sym>
ramunitid dfb $00     ; store the device's unit number here


**********************   DATA  **********************

*********** MLI call parameters ***********
*<sym>
quit_parms              ; QUIT call
        hex 04
        hex 0000
        hex 00
        hex 0000
*
*<sym>
c0_parms                ; CREATE file
        hex 07
        da fname        ; path name (same as open)
        hex C3
        hex 00
        hex 0000
        hex 00
        hex 0000
        hex 0000
*<sym>
cb_parms                ; WRITE file
        hex 04
*<sym>
refw    hex 00
*<sym>
datab   hex 0020
*<sym>
lengw   hex 272F
*<sym>
        hex 0000

*<sym>
c1_parms                ; DESTROY file
        hex 01
        da fname        ; path name (same as open)
*<sym>
cc_parms                ; CLOSE file
        hex 01          ; number of params.
        hex 00
*<sym>
c8_parms                ; OPEN file for reading             
        hex 03          ; number of params.
        da fname        ; path name
*<sym>
fbuff   hex 0000
*<sym>
ref     hex 00          ; ref ID 
*<sym>
fname   ds 16
*
*<sym>
ce_param                ; SET_MARK
        hex 02          ; number of params.
*<sym>
refce   hex 00          ; ref ID
*<sym>
filepos hex 000000      ; new file position
*
*<sym>
ca_parms                ; READ file
        hex 04          ; number of params.
*<sym>
refread hex 00          ; ref #
*<sym>
rdbuffa da rdbuff
*<sym>
rreq    hex 0000        ; bytes requested
*<sym>
readlen hex 0000        ; bytes read
*<sym>
*
rdbuff  ds 256
*<sym>
*
*<sym>
c7_param                ; GET_PREFIX
        hex 01          ; number of params.
        da path
*
*<sym>
c6_param                ; SET_PREFIX
        hex 01          ; number of params.
        da path
*
*<sym>
c5_param                ; ONLINE  
        hex 02          ; number of params.
*<sym>
unit    hex 00
        da path
*
*<sym>
path    ds 256          ; storage for path
*
*<sym>
c4_param                ; GET_FILE_INFO
        hex 0A
        da path
*<sym>
access  hex 00
*<sym>
ftype   hex 00
*<sym>
auxtype hex 0000
*<sym>
stotype hex 00
*<sym>
blocks  hex 0000
*<sym>
date    hex 0000
*<sym>
time    hex 0000
cdate   hex 0000
*<sym>
ctime   hex 0000
*
*<sym>
d1_param                ; GET_EOF
        hex 02
*<sym>
refd1   hex 00
*<sym>
filelength      ds 3

*********************** vars ***********************
*<sym>
myfac   ds 6            ; to store tempo FAC
*<sym>
counter hex 000000      ; store any counter here
*<sym>
wordscnt   hex 000000

*<sym>
recnum  hex 000000
*<sym>
tempo   hex 0000
*<sym>

draft   hex 00
*<sym>
progdiv hex 00
*<sym>


*<sym>
tohex   asc '0123456789ABCDEF'

*<sym>
letter  ds 1            ; letter 
*<sym>
pos     ds 1            ; position of letter in pattern

*<sym>
savech  ds 1
*<sym>
quitflag da 1
*<sym>
savebit ds 1
*<sym>
col     ds 1
*<sym>
pbpos   ds 1
*<sym>
displayed ds 1
*<sym>

**** strings ****
*<sym>
kolib   str "Error : "
*<sym>
oklib   str "operation ok"
*<sym>
filelib str 'index file : '
*<sym>
totallib str 'Found words : '
*<sym>
patternlib      str 'Enter pattern (A-Z and ?) : '
*<sym>
kopatlib        str 'Error in pattern !'
*<sym>
patlib          str 'Pattern : '
*<sym>
seplib          str ' : '
*<sym>
titlelib        asc ' C R O S S W ? R D   S O L V E R (v. 2.1 - French - ODS9++)'
                hex 00

*<sym>
words           str 'WORDS'
*<sym>
presskeylib     str 'Press a any key... (or esc. to abort)'

*<sym>
pattern ds 16
*<sym>
refword ds 1
**************************************************
*<sym>
prgend  equ *