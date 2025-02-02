
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
        rts             ; and return