;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.19.+ by BSZ
;---	Send/Receive test, 1bit, computer side
;---	USND1/URCV1 commands on drive side, preferred communication method
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"sr1b-usr-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC SEND+RECV 1BIT:"
		BYT	ascii_return,"USND1/URCV1 COMMANDS, PREFERRED METHOD",ascii_return,0

		jsr	sd2i_scanning_bus
		sta	z_fa				;Set SD2IEC Unit No
		cmp	#0				;Any SD2IEC on the bus?
		bne	$$sd2iecpresent
		jsr	rom_primm
		BYT	ascii_return,"NO SD2IEC DETECTED",0
		jmp	$$exit
$$sd2iecpresent	jsr	rom_primm
		BYT	ascii_return,"SD2IEC UNIT NO: #",0
		lda	#0
		ldx	z_fa
		jsr	bas_linprt
		jsr	sd2i_checkvcpusupport		;Check SD2IEC VCPU support
		bcc	$$vcpuready
		jmp	$$exit
$$vcpuready	jsr	rom_primm
		BYT	ascii_return,"DOWNLOAD CODE TO DRV",0
		jsr	sd2i_writememory
		ADR	_drivecode
		ADR	_drivecode_end-_drivecode
		ADR	drivecode_start

		jsr	rom_primm
		BYT	ascii_return,"START CODE IN DRV",0
		ldx	#lo(drivecode_start)
		ldy	#hi(drivecode_start)
		jsr	sd2i_execmemory_simple

		jsr	rom_primm
		BYT	ascii_return,"  -SPACE TO EXIT-"
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,0
		jsr	fillscreenfordata
		ldx	#10
		jsr	wait_frames

		lda	#0
		sta	z_ndx		;Clear Interrupt's keyboard buffer
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

$$commtestcycle
    IF target_platform = 20
		lda	$911f			;VIA1 DRA
		and	#%00000011
		cmp	#%00000011		;CLK+DAT = high?
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	$dd00			;CIA port for handle serial lines
		and	#%11000000
		cmp	#%11000000		;DAT+CLK = high?
    ELSEIF target_platform = 264
		lda	$01
		and	#%11000000
		cmp	#%11000000		;CLK+DAT = high?
    ENDIF
		bne	$$commtestcycle
		lda	z_ndx			;Any key pressed?
		beq	$$nokeypressed
$$exittestcyc	lda	#$00			;EXIT
		jsr	bytesender
		jsr	rom_primm
		BYT	ascii_return,"COMM TEST END.",0
		jmp	$$statexit

$$nokeypressed	lda	#%01100110
		jsr	bytesender		;CONTINUE

		inc	$$datastart
		lda	$$datastart
		sta	$$data
		ldy	#$00
$$sendcyc	lda	$$data
		jsr	bytesender
		inc	$$data
		iny
		bne	$$sendcyc

    IF target_platform = 20
		lda	#%11011100		;Release CLK, DAT
		sta	$912c
		jsr	_wait6
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#def_cia_vicbank | %00000000	;Release ATN, CLK, DAT
		sta	$dd00
		jsr	_wait6
    ELSEIF target_platform = 264
		lda	#%00001000		;Cas.Mtr Off, Release CLK, DAT
		sta	$01
		jsr	_wait6
    ENDIF

$$recvcyc	jsr	bytereceiver
		sta	screen_addr,y
		iny
		bne	$$recvcyc

		lda	$$datastart
		ldy	#0
		jsr	datachecker		;Check received BYTEs
		bcs	$$exittestcyc
		jmp	$$commtestcycle

$$statexit
    IF target_platform = 20
		lda	#%11011100		;Release CLK, DAT
		sta	$912c
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#def_cia_vicbank | %00000000	;Release CLK, DAT (ATN)
		sta	$dd00
    ELSEIF target_platform = 264
		lda	#%00001111		;Restore DDR
		sta	$00
		lda	#%00001000		;Cas.Mtr Off, Release CLK, DAT (ATN)
		sta	$01
    ENDIF
		jsr	rom_primm
		BYT	ascii_up,ascii_return,"EXIT, GET DRV STATUS:",ascii_return,0
		ldx	#5
		jsr	wait_frames
		jsr	sd2i_printstatus
		lda	#0
		sta	z_ndx			;Clear keyboard buffer
$$exit		rts

$$datastart	BYT	$00
$$data		BYT	$00


;---	Send BYTE to drive:
bytesender
    IF target_platform = 20
		sta	z_eal
		ldx	#3
$$bytesender_cy	lda	#%11011110		;Drive CLK
		lsr	z_eal
		bcs	$$bitset1
		lda	#%11111110		;Drive CLK + DAT, if sended bit = 0
$$bitset1	sta	$912c			;VIA2 PCR
		lda	#%11011100		;Release CLK
		lsr	z_eal
		bcs	$$bitset2
		lda	#%11111100		;Release CLK, Drive DAT, if sended bit = 0
$$bitset2	sta	$912c			;VIA2 PCR
		dex
		bpl	$$bytesender_cy
		rts
    ELSEIF (target_platform = 64) || (target_platform = 128)
		sta	z_eal
		ldx	#3
$$bytesender_cy	lda	#def_cia_vicbank | %00010000	;Drive CLK
		lsr	z_eal
		bcs	$$bitset1
		lda	#def_cia_vicbank | %00110000	;Drive CLK + DAT, if sended bit = 0
$$bitset1	sta	$dd00
		lda	#def_cia_vicbank | %00000000	;Release CLK
		lsr	z_eal
		bcs	$$bitset2
		lda	#def_cia_vicbank | %00100000	;Release CLK, Drive DAT, if sended bit = 0
$$bitset2	sta	$dd00
		dex
		bpl	$$bytesender_cy
		rts
    ELSEIF target_platform = 264
		eor	#%11111111		;Inverted drive of DAT line
		sta	z_eal
		ldx	#3
$$bytesender_cy	lda	#%00000101		;Cas.Mtr Off, Drive CLK
		lsr	z_eal
		rol	a			;1 bit to DAT
		sta	$01			;Drive lines
		lda	#%00000100		;Cas.Mtr Off, Release CLK
		lsr	z_eal
		rol	a			;1 bit to DAT
		sta	$01
		dex
		bpl	$$bytesender_cy
		rts
    ENDIF

;---	Receive BYTE from drive:
bytereceiver
    IF target_platform = 20
		sty	z_eal			;Y save
		ldx	#%11011110		;Drive CLK
		ldy	#%11011100		;Release CLK

		lda	$911f			;Read B0
		stx	$912c			;Drive CLK
		lsr	a
		lsr	a
		ror	z_eah
		lda	$911f			;Read B1
		sty	$912c			;Release CLK
		lsr	a
		lsr	a
		ror	z_eah
		lda	$911f			;Read B2
		stx	$912c			;Drive CLK
		lsr	a
		lsr	a
		ror	z_eah
		lda	$911f			;Read B3
		sty	$912c			;Release CLK
		lsr	a
		lsr	a
		ror	z_eah
		lda	$911f			;Read B4
		stx	$912c			;Drive CLK
		lsr	a
		lsr	a
		ror	z_eah
		lda	$911f			;Read B5
		sty	$912c			;Release CLK
		lsr	a
		lsr	a
		ror	z_eah
		lda	$911f			;Read B6
		stx	$912c			;Drive CLK
		lsr	a
		lsr	a
		ror	z_eah
		lda	$911f			;Read B7
		sty	$912c			;Release CLK
		lsr	a
		lsr	a
		ror	z_eah
		lda	z_eah
		ldy	z_eal
		rts
    ELSEIF (target_platform = 64) || (target_platform = 128)
		sty	z_eal			;Y save
		ldx	#def_cia_vicbank | %00010000	;Drive CLK
		ldy	#def_cia_vicbank | %00000000	;Release CLK

		lda	$dd00			;Read B0
		stx	$dd00			;Drive CLK
		lsr	a
		eor	$dd00			;Read B1
		sty	$dd00			;Release CLK
		lsr	a
		eor	$dd00			;Read B2
		stx	$dd00			;Drive CLK
		lsr	a
		eor	$dd00			;Read B3
		sty	$dd00			;Release CLK
		lsr	a
		eor	$dd00			;Read B4
		stx	$dd00			;Drive CLK
		lsr	a
		eor	$dd00			;Read B5
		sty	$dd00			;Release CLK
		lsr	a
		eor	$dd00			;Read B6
		stx	$dd00			;Drive CLK
		lsr	a
		eor	#%00111010
		eor	$dd00			;Read B7
		sty	$dd00			;Release CLK
		ldy	z_eal
		rts
    ELSEIF target_platform = 264
		sty	z_eal			;Y save
		ldx	#%00001010		;CLK LOW
		ldy	#%00001000		;CLK HIGH

		lda	$01			;Read B0
		stx	$01			;Drive CLK
		lsr	a
		eor	$01			;Read B1
		sty	$01			;Release CLK
		lsr	a
		eor	$01			;Read B2
		stx	$01			;Drive CLK
		lsr	a
		eor	$01			;Read B3
		sty	$01			;Release CLK
		lsr	a
		eor	$01			;Read B4
		stx	$01			;Drive CLK
		lsr	a
		eor	$01			;Read B5
		sty	$01			;Release CLK
		lsr	a
		eor	$01			;Read B6
		stx	$01			;Drive CLK
		lsr	a
		eor	#%00100111
		eor	$01			;Read B7
		sty	$01			;Release CLK
		ldy	z_eal
		rts
    ENDIF

;---	Waits:
_wait6		nop
_wait5		nop
_wait4		nop
_wait3		nop
_wait2		nop
_wait1		nop
_wait0		rts
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode	BINCLUDE "sr1b-usr-drive.prg"
_drivecode_end
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/datachecker.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/waittime.asm"
;------------------------------------------------------------------------------
