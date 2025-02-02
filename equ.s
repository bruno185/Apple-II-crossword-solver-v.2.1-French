* * * * * * * * * * * * * * * * * * * * * * 
*                     EQUates             *
* * * * * * * * * * * * * * * * * * * * * * 
*
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
crout           equ $FD8E       ; print carriage return 
clreop          equ $FC42       ; clear from cursor to end of page
clreol          equ $FC9C       ; clear from cursor to end of line
xtohex          equ $F944
rdkey           equ $FD0C       ; wait for keypress
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
*
***********************    my equ  ***********************
*
bitmap1  equ $2000      ; $2000 -> $5FFF (bitmap index 1) => aux mem.
bitmap2  equ $4000      ; $6000 -> $9FFF (bitmap index 2) => aux mem.

ptr1     equ $06        ;
ptr2     equ $08
reclength equ $10       ; length of record in words file
pbline  equ $03         ; # of text line for progressbar
pbchar  equ #'-'        ; char for progressbar
pbora   equ #$80        ; char bit 7 for progressbar
