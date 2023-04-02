;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.12.+ by BSZ
;---	File Load test, 2bit, computer side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"../common/len_chks.asm"
	INCLUDE	"loadtst2b-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC MEGABYTES LOAD TEST, 2BIT:",0
		jsr	sd2i_scanning_bus
		sta	z_fa				;Set SD2IEC Unit No
		cmp	#0				;Any SD2IEC on the bus?
		bne	$$sd2iecpresent
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"NO SD2IEC DETECTED",0
		jmp	$$exit
$$sd2iecpresent	cpx	#1				;Only one device connected to serial bus?
		beq	$$onlyone
		jsr	rom_primm
		BYT	ascii_return,"ONLY ONE DEVICE ALLOWED",0
		jmp	$$exit
$$onlyone	jsr	rom_primm
		BYT	ascii_return,ascii_return,"SD2IEC UNIT NO: #",0
		lda	#0
		ldx	z_fa
		jsr	bas_linprt
		jsr	sd2i_checkvcpusupport		;Check SD2IEC VCPU support
		bcc	$$vcpuready
		jmp	$$exit
$$vcpuready

    IF target_platform = 20
		lda	#%11011100		;Release CLK, DAT
		sta	$912c
		lda	#%01111111
		sta	$911f			;Release ATN
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#def_cia_vicbank | %00000000	;Release ATN, CLK, DAT
		sta	$dd00
		lda	#%00111111			;Only DAT/CLK in input
		sta	$dd02
    ELSEIF target_platform = 264
		lda	#%00001000		;Cas.Mtr Off, Release ATN, CLK, DAT
		sta	$01
		lda	#%00011111		;Dirty Hack: Datasette RD line output and drive LOW
		sta	$00			;B4 always 0 after read port
    ENDIF

		jsr	rom_primm
		BYT	ascii_return,"LD2:254+CHK:",0
		lda	#%00000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LD2:254/NCK:",0
		lda	#%10000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LD2:256+CHK:",0
		lda	#%01000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"LD2:256/NCK:",0
		lda	#%11000001
		jsr	loader
		bcs	$$loaderror
		jsr	printdata
		jmp	$$statexit

$$loaderror	jsr	rom_primm
		BYT	" !!!LOAD ERROR!!!",0

$$statexit
    IF target_platform = 20
		lda	#%11011100		;Release CLK, DAT
		sta	$912c
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#def_cia_vicbank | %00000000	;Release CLK, DAT, ATN
		sta	$dd00
    ELSEIF target_platform = 264
		lda	#%00001111		;Restore DDR
		sta	$00
		lda	#%00001000		;Cas.Mtr Off, Release CLK, DAT, ATN
		sta	$01
    ENDIF
		jsr	rom_primm
		BYT	ascii_return,"EXIT, GET DRV STATUS:",ascii_return,0
		ldx	#5
		jsr	wait_frames
		jsr	sd2i_printstatus
		lda	#0
		sta	z_ndx			;Clear keyboard buffer
$$exit		rts
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

$$loadcycle	lda	_rtsopcode		;RTS
		sta	$$bytereceivr_e		;cycle changed to one-run


    IF target_platform = 20
		ldy	#%00000000		;Release ATN (preparation)
$$waitnotbusy	lda	$911f			;VIA1 DRA
		and	#%00000011
    ELSEIF (target_platform = 64) || (target_platform = 128)
		ldy	#def_cia_vicbank | %00000000	;Release ATN (preparation)
$$waitnotbusy	lda	$dd00				;CIA port for handle serial lines
		and	#%11000000
    ELSEIF target_platform = 264
		ldy	#%00001000		;Release ATN (preparation)
$$waitnotbusy	lda	$01			;CPU port for handle serial lines
		and	#%11000000
    ENDIF
		beq	$$waitnotbusy
		jsr	$$bytereceivr_c		;Get initial byte
		and	#%11110000
		cmp	#%11000000		;End of file?
		beq	$$loadended
		cmp	#%00110000		;ERROR?
		beq	$$error
		jsr	$$bytereceivr_c		;Get number of bytes
		sta	screen_addr+$0101
		tax
		inx
		stx	$$bytereceivr_k+1
		stx	_byteno
		jsr	lengthcalc		;Add BYTEno to Length
		lda	_brecvopcode
		sta	$$bytereceivr_e		;cycle restored

		ldx	#0
$$bytereceivr_c
    IF target_platform = 20
		stx	z_eah			;X save
		ldx	#%10000000		;Drive ATN (preparation)

		lda	$911f			;Read B10
		stx	$911f			;Drive ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal			;B3210 -> B7654
		lda	$911f			;Read B32
		sty	$911f			;Release ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal			;B3210 -> B7654
		lda	$911f			;Read B54
		stx	$911f			;Drive ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal			;B543210 -> B765432
		lda	$911f			;Read B76
		sty	$911f			;Release ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal			;B76543210 -> B76543210
		ldx	z_eah			;X restore
		lda	z_eal			;Read received data
    ELSEIF (target_platform = 64) || (target_platform = 128)
		stx	z_eal				;X save
		ldx	#def_cia_vicbank | %00001000	;Drive ATN (preparation)
		lda	$dd00				;Read B10
		stx	$dd00				;Drive ATN
		lsr	a
		lsr	a
		eor	$dd00				;Read B32
		sty	$dd00				;Release ATN
		lsr	a
		lsr	a
		eor	$dd00				;Read B54
		stx	$dd00				;Drive ATN
		lsr	a
		lsr	a
		eor	$dd00				;Read B76
		sty	$dd00				;Release ATN
		eor	#%00001110
		ldx	z_eal
    ELSEIF target_platform = 264
		stx	z_eal
		ldx	#%00001100		;Drive ATN (preparation)
		lda	$01			;Read B10
		stx	$01			;Drive ATN
		lsr	a
		lsr	a
		eor	$01			;Read B32
		sty	$01			;Release ATN
		lsr	a
		lsr	a
		eor	$01			;Read B54
		stx	$01			;Drive ATN
		lsr	a
		lsr	a
		eor	#%00001110
		eor	$01			;Read B76
		sty	$01			;Release ATN
		ldx	z_eal
    ENDIF
$$bytereceivr_e	sta	screen_addr,x
		inx
$$bytereceivr_k	cpx	#$00
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

$$loadended	jsr	$$bytereceivr_c		;Get CheckSum LO
		sta	_checksum+3
		jsr	_wait8
		jsr	$$bytereceivr_c		;Get CheckSum MID
		sta	_checksum+4
		jsr	_wait8
		jsr	$$bytereceivr_c		;Get CheckSum HI
		sta	_checksum+5
		jsr	$$bytereceivr_c		;Get Length LO
		sta	_length+3
		jsr	_wait8
		jsr	$$bytereceivr_c		;Get Length MID
		sta	_length+4
		jsr	_wait8
		jsr	$$bytereceivr_c		;Get Length HI
		sta	_length+5

restoreirq	sei
		lda	#lo(rom_nirq)
		sta	$0314
		lda	#hi(rom_nirq)
		sta	$0315
		cli
		clc				;OK
		rts

_wait8		nop
		nop
		nop
		nop
_rtsopcode	rts
_brecvopcode	sta	screen_addr,x
;------------------------------------------------------------------------------
;	CHKSUM calculation:
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
    IF target_platform = 20
		inc	$900f			;Change border color
		bit	$9124			;Clear Interrupt flag
    ELSEIF target_platform = 64
		inc	$d020			;Change border color
		bit	$dc0d			;Clear interrupt flag
    ELSEIF target_platform = 264
		inc	$ff19			;Change border color
		lda	#$ff
		sta	$ff09			;Clear interrupt flag
    ELSEIF target_platform = 128
		inc	$d020			;Change border color
		lda	$d019
		sta	$d019			;Clear interrupt flag
    ENDIF
		inc	_time+0
		bne	$$interrupt_end
		inc	_time+1
$$interrupt_end
    IF target_platform = 20
		dec	$900f			;Restore border color
    ELSEIF (target_platform = 64) || (target_platform = 128)
		dec	$d020			;Restore border color
    ELSEIF target_platform = 264
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
		jsr	sd2i_writememory
		ADR	_drivecode
		ADR	_drivecode_end-_drivecode
		ADR	drivecode_start
		lda	#'E'
		jsr	rom_bsout
		ldx	#lo(drivecode_go)
		ldy	#hi(drivecode_go)
		jsr	sd2i_execmemory_simple
		ldx	#10
		jsr	wait_frames
		lda	#'L'
		jmp	rom_bsout
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode
_modebits
	BINCLUDE "loadtst2b-drive.prg"
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
