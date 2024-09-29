;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2024.08.13.+ by BSZ
;---	File Load test, parallel port, computer side
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
	INCLUDE	"../common/hosthwmacros.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"../common/len_chks.asm"
	INCLUDE	"loadtstpp-drive.inc"
;------------------------------------------------------------------------------
;---	Actual testfile
megafile_length	=	meg1file_length
megafile_chks	=	meg1file_chks
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC MEGABYTES LOAD TEST, PARALLEL:",0
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
		cmp	#4<<5				;SER+PAR?
		beq	$$vcpuparallel
		cmp	#5<<5				;FASTSER+PAR?
		beq	$$vcpuparallel
		jsr	rom_primm
		BYT	ascii_return,"DRIVE NOT SUPPORT PARALLEL PORT",0
		jmp	$$exit
$$vcpuparallel	jsr	_downloadcode			;Download drivecode
		ldx	#lo(drivecode_ppc)
		ldy	#hi(drivecode_ppc)
		jsr	sd2i_execmemory_simple

		pp_hwinit			;Inicialize HW
		jsr	checkparallellink
		bcc	$$parlinkok
		pp_hwdeinit			;Reset HW to default state
		jmp	$$exit

$$parlinkok	jsr	rom_primm
		BYT	ascii_return,"LDPP:254+CHK:",0
		lda	#%00000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LDPP:254/NCK:",0
		lda	#%10000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LDPP:256+CHK:",0
		lda	#%01000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LDPP:256/NCK:",0
		lda	#%11000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jmp	$$statexit

$$loaderror	jsr	rom_primm
		BYT	" !!!LOAD ERROR!!!",0

$$statexit	pp_hwdeinit			;Reset HW to default state
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
		ser_starttransfer		;Sync

		jsr	datainit		;Clear calculated data

		jsr	fillscreenfordata

		ldx	#lo(interrupt)
		ldy	#hi(interrupt)
		sei
		stx	$0314
		sty	$0315
		cli

$$loadcycle	ser_getclkdat			;Get CLK -> N, DAT -> Cy
		bmi	$$error			;If CLK High, load error
		bcc	$$loadcycle		;If DAT Low, drive BUSY, wait...
		pp_readport			;Get initial byte
		and	#%11110000
		cmp	#%11000000		;End of file?
		beq	$$loadended
		cmp	#%00110000		;ERROR?
		beq	$$error
		pp_readport			;Get number of bytes
		sta	screen_addr+$0101
		tax
		inx
		stx	$$bytereceivr_k+1
		stx	_byteno
		jsr	lengthcalc		;Add BYTEno to Length

		ldy	#0
$$bytereceivr_c	pp_readport			;Get BYTE from file
		sta	screen_addr,y
		iny
$$bytereceivr_k	cpy	#$00
		bne	$$bytereceivr_c		;Go to get next BYTE

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

$$loadended	pp_readport			;Get CheckSum LO
		sta	_checksum+3
		pp_readport			;Get CheckSum MID
		sta	_checksum+4
		pp_readport			;Get CheckSum HI
		sta	_checksum+5
		pp_readport			;Get Length LO
		sta	_length+3
		pp_readport			;Get Length MID
		sta	_length+4
		pp_readport			;Get Length HI
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
    IF target_platform == 20
		inc	$900f			;Change border color
		bit	$9124			;Clear Interrupt flag
    ELSEIF target_platform == 64
		inc	$d020			;Change border color
		bit	$dc0d			;Clear interrupt flag
    ELSEIF target_platform == 264
		inc	$ff19			;Change border color
		lda	#$ff
		sta	$ff09			;Clear interrupt flag
    ELSEIF target_platform == 128
		inc	$d020			;Change border color
		lda	$d019
		sta	$d019			;Clear interrupt flag
    ENDIF
		inc	_time+0
		bne	$$interrupt_end
		inc	_time+1
$$interrupt_end
    IF target_platform == 20
		dec	$900f			;Restore border color
    ELSEIF (target_platform == 64) || (target_platform == 128)
		dec	$d020			;Restore border color
    ELSEIF target_platform == 264
		dec	$ff19			;Restore border color
    ENDIF
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
;---	Check parallel link:
checkparallellink

		sei
		jsr	rom_primm
		BYT	ascii_return,"CHECK PARALLEL LINK:",0

		pp_porttoin			;Switch parport to input
		ser_waitclklo			;Wait for CLK line Low
		pp_clrdrwp			;Clear DRW flag
		ser_setdat 0			;Set DAT to low
		pp_chkdrwp			;Check DRW flag
		beq	$$noparallel		;If new data not present, ERROR
		pp_clrdrwp			;Clear DRW flag

		pp_readport			;Read port
		cmp	#def_linkchk_byte1	;$5A?
		bne	$$noparallel
		pp_chkdrwp			;Check DRW flag
		beq	$$noparallel		;If new data not present, ERROR
		pp_clrdrwp			;Clear DRW flag

		pp_readport			;Read port
		cmp	#def_linkchk_byte2	;$A5?
		bne	$$noparallel
		ser_setdat 1			;Release DAT
		jsr	rom_primm
		BYT	" LINK OK!",0
		cli
		clc
		rts

$$noparallel	ser_setdat 1			;Release DAT
		jsr	rom_primm
		BYT	" LINK ERROR!",0
		cli
		sec				;No correct parallel link
		rts
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode
_modebits
	BINCLUDE "loadtstpp-drive.bin"
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
