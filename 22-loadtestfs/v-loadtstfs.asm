;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.10.17.+ by BSZ
;---	File Load test, C128, Fast Serial, computer side
;---	  Comment: Data send/receive works on a timing instead of checking
;---		   the SP flag of the CIA. This flag is cleared by the
;---		   original C128 interrupt routine, and this conflicts with
;---		   the current test codes.
;---	240325+: Testfile changed
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"../common/len_chks.asm"
	INCLUDE	"loadtstfs-drive.inc"
;------------------------------------------------------------------------------
;---	Actual testfile
megafile_length	=	meg1file_length
megafile_chks	=	meg1file_chks
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC MEGABYTES LOAD TEST, FAST SERIAL:",0

    IF target_platform <> 128
	INCLUDE "../common/c128onlytxt.asm"
    ELSE
		jsr	sd2i_scanning_bus
		sta	z_fa				;Set SD2IEC Unit No
		cmp	#0				;Any SD2IEC on the bus?
		bne	$$sd2iecpresent
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"NO SD2IEC DETECTED",0
		jmp	$$exit
$$sd2iecpresent	jsr	rom_primm
		BYT	ascii_return,ascii_return,"SD2IEC UNIT NO: #",0
		lda	#0
		ldx	z_fa
		jsr	bas_linprt
		jsr	sd2i_checkvcpusupport		;Check SD2IEC VCPU support
		bcc	$$vcpuready
		jmp	$$exit
$$vcpuready	lda	_vcpu_version			;VCPU version + bus type
		and	#%11100000			;Bus type remain
		cmp	#3<<5				;FASTSER?
		beq	$$vcpufastser
		cmp	#5<<5				;FASTSER+PAR?
		beq	$$vcpufastser
		jsr	rom_primm
		BYT	ascii_return,"DRIVE NOT SUPPORT FAST SERIAL",0
		jmp	$$exit
$$vcpufastser	jsr	_downloadcode			;Download drivecode
		ldx	#lo(drivecode_fsc)
		ldy	#hi(drivecode_fsc)
		jsr	sd2i_execmemory_simple

		jsr	checkfslink
		bcc	$$fslinkok
		jmp	$$exit

$$fslinkok	jsr	rom_primm
		BYT	ascii_return,"LDFS:254+CHK:",0
		lda	#%00000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LDFS:254/NCK:",0
		lda	#%10000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LDFS:256+CHK:",0
		lda	#%01000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LDFS:256/NCK:",0
		lda	#%11000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jmp	$$statexit

$$loaderror	jsr	rom_primm
		BYT	" !!!LOAD ERROR!!!",0

$$statexit	lda	$dd00
		and	#%11000111			;Release ATN, CLK, DAT
		sta	$dd00
		jsr	rom_primm
		BYT	ascii_return,"EXIT, GET DRV STATUS:",ascii_return,0
		ldx	#5
		jsr	wait_frames
		jsr	sd2i_printstatus
		lda	#0
		sta	z_ndx			;Clear keyboard buffer
$$exit		jmp	program_exit
;------------------------------------------------------------------------------
;---	Loader:
;---	A <- B7=0: calc chksum, =1: no calc chksum, B6=0: 254, =1: 256 BYTEs

loader		sta	_modebits

		jsr	downloadstartcode	;Download + Start code

		jsr	datainit		;Clear calculated data

		jsr	fillscreenfordata

		ldx	#lo(interrupt)
		ldy	#hi(interrupt)
		sei
		stx	$0314
		sty	$0315
		cli

$$loadcycle	lda	$dd00
		and	#%11000111
		sta	$dd00
		ora	#%00010000		;CLK drive (prepare)
		tax

$$waitnotbusy	bit	$dd00
		bvc	$$waitnotbusy
		jsr	fsbytereceiverw		;Wait and get BYTE, sign of read (status)
		and	#%11110000
		cmp	#%11000000		;End of file?
		beq	$$loadended
		cmp	#%00110000		;ERROR?
		beq	$$error
		jsr	fsbytereceiverw		;Wait and get BYTE, sign of read (number of bytes)
		sta	screen_addr+$0101
		tay
		iny
		sty	_byteno
		sty	z_eal			;Block length
		jsr	lengthcalc		;Add BYTEno to Length

		ldy	#0
$$bytereceiver	jsr	fsbytereceiver		;33
		sta	screen_addr,y		;5	Store received BYTE
		nop				;2
		iny				;2
		cpy	z_eal			;3
		bne	$$bytereceiver		;3(2)	48 clk cycle

		lda	$dd00
		and	#%11000111		;CLK release
		sta	$dd00

		bit	_modebits
		bmi	$$nocksumcalc
		jsr	checksumcalc
$$nocksumcalc	inc	_block+0
		bne	$$blockcntnc
		inc	_block+1
$$blockcntnc	jmp	$$loadcycle		;Read next block

$$error		jsr	restoreirq
		sec				;ERROR
		rts

$$loadended	jsr	fsbytereceiverw		;Wait and get BYTE, sign of read (CheckSum LO)
		sta	_checksum+3
		jsr	fsbytereceiverw		;Wait and get BYTE, sign of read (CheckSum MID)
		sta	_checksum+4
		jsr	fsbytereceiverw		;Wait and get BYTE, sign of read (CheckSum HI)
		sta	_checksum+5
		jsr	fsbytereceiverw		;Wait and get BYTE, sign of read (Length LO)
		sta	_length+3
		jsr	fsbytereceiverw		;Wait and get BYTE, sign of read (Length MID)
		sta	_length+4
		jsr	fsbytereceiverw		;Wait and get BYTE, sign of read (Length HI)
		sta	_length+5

restoreirq	sei
		lda	#lo(rom_nirq)
		sta	$0314
		lda	#hi(rom_nirq)
		sta	$0315
		cli
		clc				;OK
		rts
;------------------------------------------------------------------------------
;---	CHKSUM calculation:
checksumcalc	ldx	#0
$$chksumcalc_c	lda	screen_addr,x
		clc
		adc	_checksum+0
		sta	_checksum+0
		bcc	$$chksumcalc_n
		inc	_checksum+1
		bne	$$chksumcalc_n
		inc	_checksum+2
$$chksumcalc_n	inx
		cpx	_byteno
		bne	$$chksumcalc_c
		rts
;------------------------------------------------------------------------------
;---	Length calculation
;---	A <- Length - 1
lengthcalc	jsr	$$addone
		clc
		adc	_length+0
		sta	_length+0
		bcc	$$ncy
		bcs	$$cy
$$addone	inc	_length+0
		bne	$$ncy
$$cy		inc	_length+1
		bne	$$ncy
		inc	_length+2
$$ncy		rts
;------------------------------------------------------------------------------
;---	Inicialize calculated data:
datainit	lda	#0
		sta	_time+0
		sta	_time+1
		sta	_block+0
		sta	_block+1
		sta	_checksum+0
		sta	_checksum+1
		sta	_checksum+2
		sta	_length+0
		sta	_length+1
		sta	_length+2
		rts
;------------------------------------------------------------------------------
;---	Interrupt routine for time measure:
interrupt
		inc	$d020			;Change border color
		lda	$d019
		sta	$d019			;Clear interrupt flag
		inc	_time+0
		bne	$$interrupt_end
		inc	_time+1
$$interrupt_end
		dec	$d020			;Restore border color
		jmp	rom_prend
;------------------------------------------------------------------------------
;---	Print loaded file details:
printdata	jsr	rom_primm
		BYT	" TM:",0
		ldx	_time+0
		lda	_time+1				;A:X: counted frames
		jsr	bas_linprt
		jsr	rom_primm
		BYT	" BL:",0
		ldx	_block+0
		lda	_block+1			;A:X: counted blocks
		jsr	bas_linprt
		jsr	rom_primm
		BYT	ascii_return," CS,L-C/R:",0
		lda	_checksum+2
		jsr	mon_puthex
		lda	_checksum+1
		jsr	mon_puthex
		lda	_checksum+0
		jsr	mon_puthex
		lda	#"/"
		jsr	rom_bsout
		lda	_checksum+5
		jsr	mon_puthex
		lda	_checksum+4
		jsr	mon_puthex
		lda	_checksum+3
		jsr	mon_puthex
		lda	#","
		jsr	rom_bsout
		lda	_length+2
		jsr	mon_puthex
		lda	_length+1
		jsr	mon_puthex
		lda	_length+0
		jsr	mon_puthex
		lda	#"/"
		jsr	rom_bsout
		lda	_length+5
		jsr	mon_puthex
		lda	_length+4
		jsr	mon_puthex
		lda	_length+3
		jsr	mon_puthex

		bit	_modebits			;B7=0: ChkSum calculated
		bmi	$$chksok			;If not calculated, no compare
		lda	_checksum+0
		cmp	_checksum+3
		bne	$$chkserror
		cmp	#(megafile_chks & $ff)
		bne	$$chkserror
		lda	_checksum+1
		cmp	_checksum+4
		bne	$$chkserror
		cmp	#((megafile_chks >> 8) & $ff)
		bne	$$chkserror
		lda	_checksum+2
		cmp	_checksum+5
		bne	$$chkserror
		cmp	#((megafile_chks >> 16) & $ff)
		beq	$$chksok
$$chkserror	jsr	rom_primm
		BYT	" !!!CKS ERROR!!!",0
$$chksok	rts
;------------------------------------------------------------------------------
;---	Download code to SD2IEC and Start:
downloadstartcode
		lda	#'D'
		jsr	rom_bsout
		jsr	_downloadcode
		lda	#'E'
		jsr	rom_bsout
		ldx	#lo(drivecode_ld)
		ldy	#hi(drivecode_ld)
		jsr	sd2i_execmemory_simple
		ldx	#10
		jsr	wait_frames
		lda	#'L'
		jmp	rom_bsout

_downloadcode	jsr	sd2i_writememory
		ADR	_drivecode
		ADR	_drivecode_end-_drivecode
		ADR	drivecode_start
		rts
;------------------------------------------------------------------------------
;---	Check Fast Serial link:
checkfslink	sei
		jsr	rom_primm
		BYT	ascii_return,"CHECK FASTSER LINK:",0

		clc
		jsr	rom_spin_spout		;Set to input (receive)
		bit	$dc0d			;Clear SDR flag

$$waitclkl	bit	$dd00
		bvs	$$waitclkl		;Wait for CLK low

		lda	$dd00
		ora	#%00100000
		sta	$dd00			;DAT to Low
		and	#%11011111
		sta	$dd00			;DAT to HiZ
$$waitclkh	bit	$dd00
		bvc	$$waitclkh		;Wait for CLK Hi

		lda	$dc0d			;ICR
		and	#%00001000		;SDR flag?
		beq	$$nofastserdat
		lda	#'R'
		jsr	rom_bsout
		lda	$dc0c			;SDR
		cmp	#def_linkchk_byte	;Transmitted BYTE?
		bne	$$bugfastserdat
		jsr	mon_puthex
		jsr	rom_primm
		BYT	" LINK OK!",0
		cli
		clc
		rts

$$nofastserdat	lda	#'X'
		jsr	rom_bsout
		lda	$dc0c			;SDR
$$bugfastserdat	jsr	mon_puthex
		jsr	rom_primm
		BYT	" LINK ERROR!",0
		cli
		sec				;No Fast Serial data received
		rts
;------------------------------------------------------------------------------
;---	Wait 64+6+6 clk. cycle (one BYTE transmit + jitter)
fsbytewait	jsr	$$wait			;12
		jsr	$$wait			;12
		jsr	$$wait			;12
		jsr	$$wait			;12
		jsr	$$wait			;12
		bit	$dc0d			;4	Clear SDR flag
$$wait		rts				;6	76 with JSR
;------------------------------------------------------------------------------
;---	Wait a bit, and get BYTE from fast serial:
fsbytereceiverw	jsr	fsbytewait

;---	Get BYTE from fast serial:
;---	A -> received BYTE
fsbytereceiver	lda	$dc0c			;4	Get data from SDR
		stx	$dd00			;4	Set Clock
		pha				;3
		txa				;2
		eor	#%00010000		;2	Toggle CLK
		tax				;2
		pla				;4
		rts				;6	33 with JSR
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode
_modebits
	BINCLUDE "loadtstfs-drive.bin"
_drivecode_end
;------------------------------------------------------------------------------
_time		BYT	0,0
_block		BYT	0,0
_checksum	BYT	0,0,0, 0,0,0
_length		BYT	0,0,0, 0,0,0
_byteno		BYT	0
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE	"../common/datachecker.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/waittime.asm"
;------------------------------------------------------------------------------
    ENDIF
;------------------------------------------------------------------------------
