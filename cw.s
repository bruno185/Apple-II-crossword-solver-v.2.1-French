************************
*   crossword solver   * 
************************
* \
* Purpose : perform fast searches in a list of over 400 000 French words using patterns
* Uses special bitmap index files.
*
* Main program flow:
* 1. Initialize variables and clear screen.
* 2. Accept user input for a pattern.
* 3. Validate the input.
* 4. Process the pattern to search for matching words.
* 5. Display results and return to the initial state.
*
* History :
* version 1.0 : uses temporary files 
* version 1.1 : remove temporary files, now operates primarily in memory
* version 1.2 : add a progress bar
* version 1.4 : 
* => new word file (ods8) 402328 words <= 15 chars, + 3 words : AIRIAL, AIRIAUX, BRIC)
* => page stop (wait a key, or esc. to abort).
* version 2.0 : split dictionary and indexes by word length
* => now indexes are smaller, they don't need to be run length encoded, 
* nor they need to be split in 4 parts.

* version 2.1 french : 
* => now include Officiel du Scrabble 9 (2024) with new words. 
* NB : the 64 words deleted by the Scrabble editor (present in ODS8) have been reinstated.
* => minor optimisations
* => debug info for Applewin debugger.
* => better comments
*
* version 2.1.1 french : 
* => the analysis of bytes resulting from the AND operation on index files 
* is now strictly limited to the required number (= length of the index file).
* In previous versions, a memory area of 8kb was analyzed (from $2000 to $3FFF).
* the same optimization applies to bit counting.
* 
* => english comments revised and enhanced by ChatGPT
*
********************  memory org.  ***********************
* Dictionary : 407192 words (402328 words in ODS8)
* ==> split in 14 parts, by number of letters (from 2 to 15)

* program : $1000 to $1FFF 
* bitmap1 : $2000 -> $3FFF  
* bitmap2 : $4000 -> $5FFF
* WARNING: these 8 kB memory areas are suitable for a maximum number of 65536 words
* of the same length, which is currently the case.
* The current maximum is 63742 for 10-letter words. 
* But this may change as more words are added in the future.
*
* buffers for OPEN MLI call (1024 bytes) : $8400 (index files) and $8800 (words files) 
*
*
*
*
********************************************************************
*                             P R O G R A M                        *
********************************************************************
        MX %11          ; for Merlin : A, X, Y 8 bits
        put mac.s       ; macros
        put equ.s       ; equates
        org $1000

*<sym>
start   equ *

        jsr doprefix    ; get prefix, define it if not already set
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
        jsr mygetln     ; allow user to input pattern
        jsr testpat     ; check if the pattern contains letters and set the 'noletter' var accordingly 
        lda quitflag    ; if ctrl-c or escape then quitflag > 0
        bne exit2       ; yes : exit program
        lda pattern     ; get pattern length
        cmp #$02        ; pattern length must be >= 2
        bpl okpat       ; pattern ok : process it
        cr              ; print return (macro)
        prnstr kopatlib ; wrong pattern, message and loop
        jsr dowait      ; wait for a key pressed
        jmp init        ; goto beginning

*<sym>
exit2   rts             ; end of program

*<bp>
*<sym>
okpat   cr              ; process pattern
        cr
********************  init vars **********************

        lda #$00        ; init. total counter (sum of counters for 4 parts, 3 bytes integer)
        sta wordscnt    ; init. word counter to 0 (3 bytes integer)
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
        lda #$00 
        sta progdiv     ; init division = 0
        lda #36         ; 36 chars for index processing (= 72 chars in 80 col.)
*<sym>
dosub   inc progdiv     ; inc division
        sec
        sbc pattern     ; substract word length 
        bpl dosub
        dec progdiv     ; adjust division
*
*
************ main loop for searching words ************
*<sym>
main
        closef #$00     ; close all files
        jsr FREEBUFR    ; free all buffers 
        jsr bigloop     ; main loop : process letters of the pattern
        jsr bigdisplay  ; print found words 
        jsr progressbarfin      ; print last chars (-) of progressbar
        jsr showres     ; show final result (count)
*<sym>
eop     jsr dowait      ; wait for a pressed key 
        closef #$00     ; close all files 
        jsr FREEBUFR    ; free all buffers
        jmp init        ; loop to the beginning
*
******************** main program end ********************
*
*


*<sym>
progressbar             ; display a progress bar while procesing index
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
* main program loop : process all letters of pattern
*<sym>
bigloop lda #$01
        sta pos         ; position in pattern = 1 (first char)
        clc
        jsr fillmem     ; fill bitmap1 ($2000-$3FFF) with $ff
                        ; fill bitmap2 ($4000-$5FFF) with $00
*<sym>
bigll   
        lda noletter    ; just "?" chars in pattern flag (no a-z A-Z)
        bne dolong      ; yes : jump to length index process
                        ; no : search (full process)
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
        da  ca_parms    ; load file at bitmap2 address
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
        jsr doand3       ; AND $2000 and $4000 areas 
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
        jsr setmax
        lda #<bitmap1   ; set pointer to $2000 area
        sta ldb+1
        lda #>bitmap1
        sta ldb+2 

        lda #$00        ; init counter
        sta counter
        sta counter+1
        sta counter+2
*<sym>
lpcnt
        ldy #$00
*<sym>
ldb 
        lda $2000       ; get byte to read
        beq updateptr   ; byte = $00 : loop
        ldx #$08        ; 8 bits to check
*<sym>
shift   lsr
        bcc nocarry     ; bit = 0
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
        inc ldb+1        ; next byte to read
        bne noincp1
        inc ldb+2
*<sym>
noincp1
        lda ldb+1
        cmp max       
        bne lpcnt
        lda ldb+2
        cmp max+1       
        bne lpcnt
        rts

******************* AND *******************
* v2.1.1 : now only the bytes needed are ANDed (and not $2000 to $3FFF) 
* The length of the area ton AND is equal to the length of the index files 
* for the current pattern
*<sym>
doand3
        jsr setmax
        lda #<bitmap1   ; set bitamp1 address
        sta loadbyte+1
        sta savebyte+1
        lda #>bitmap1
        sta loadbyte+2 
        sta savebyte+2

        lda #<bitmap2   ; set bitamp2 address
        sta andbyte+1
        lda #>bitmap2
        sta andbyte+2 
*<sym>
doandloop
*<sym>
loadbyte
        lda $2000
*<sym>
andbyte
        and $4000
*<sym>
savebyte
        sta $2000

        inc loadbyte+1
        bne :1
        inc loadbyte+2
        inc andbyte+2
        inc savebyte+2
:1
        inc andbyte+1
        inc savebyte+1

        lda loadbyte+1
        cmp max
        bne doandloop
        lda loadbyte+2 
        cmp max+1
        bne doandloop
        rts

************** readindex **************
* Prepare loading of index file 
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
************** Read user input of a pattern **************
*<sym>
mygetln                 ; to let user input pattern 
                        ; takes upper and lower case letters and ? (? = any letter)
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

*
* Fill merory work area where the index files avec loaded and ANDed.
* TODO: fill only the space required (= the length of the current index file). 
* NB: but this function is currently called before the length of the index file is known.
*<sym>
fillmem
        ; fill bitmap1 ($2000-$3FFF) with $ff
        ; fill bitmap2 ($4000-$5FFF) with $00
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
* prints to screen a 3 bytes integer in counter/counter+1/counter+2
* counter+2 must be positive

        lda counter+2           ; init fac with filelength+1/filelength+2
        ldy counter+1
        jsr float               ; convert integer to fac
        jsr mult256             ; * 256
        lda counter             ; add filelength
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
        cpx #reclength          ; no more than record length
        bne rslt
*<sym>
finres  rts

*********** Error processing ***********
*<sym>
ko      pha             ; save error code
        prnstr kolib    ; print error message
        pla             ; restore error code
        tax
        jsr xtohex      ; print error code
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
* get current prefix
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
*
        put bigdisplay.s        ; code for printing found words 
        ;put ram.s               ; disconnect /RAM, not used for now.
*
*
**********************   DATA  **********************
*
*<sym>
address dw $0000      ; store the device driver address here
*<sym>
ramunitid dfb $00     ; store the device's unit number here
*
*
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
*<m2>
*<sym>
filelength      ds 3
*<sym>
max             ds 2    ; adress of last byte to analyse (+1) = $2000 + filelength

*********************** vars ***********************
*<sym>
myfac   ds 6            ; to store tempo FAC
*<sym>
counter hex 000000      ; store any counter here
*<sym>
wordscnt   hex 000000
*<m1>
*<sym>
noletter ds 1

*<sym>
recnum  hex 000000
*<sym>
tempo   hex 0000
*<sym>
progdiv hex 00
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
patternlib      str 'Enter pattern (A-Z a-z and ?) : '
*<sym>
kopatlib        str 'Error in pattern !'
*<sym>
patlib          str 'Pattern : '
*<sym>
seplib          str ' : '
*<sym>
titlelib        asc ' C R O S S W ? R D   S O L V E R (v. 2.1.1 - French - ODS9++)'
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