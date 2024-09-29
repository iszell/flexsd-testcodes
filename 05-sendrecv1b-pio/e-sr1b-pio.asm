;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.19.+ by BSZ
;---	Send/Receive test, 1bit, computer side
;---	Programmed I/O on drive side, only for testing, not recommended for
;---	  regular use!
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"sr1b-pio-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC SEND+RECV 1BIT:"
    IF target_platform <> 20
		BYT	ascii_return,"PROGRAMMED I/O, NOT RECOMMENDED",ascii_return,0
    ELSE
		BYT	ascii_return,"PIO1B, NOT RECOMMENDED",ascii_return,ascii_up,0
    ENDIF

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
		BYT	ascii_return,"# ",ascii_rvson,"[SPACE]",ascii_rvsoff,": EXIT"
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,0
		jsr	fillscreenfordata
		ldx	#10
		jsr	wait_frames

		lda	#0
		sta	z_ndx			;Clear Interrupt's keyboard buffer
$$commtestcycle
    IF target_platform == 20
		lda	$911f			;VIA1 DRA
		and	#%00000011
		cmp	#%00000011		;DAT+CLK = high?
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	$dd00			;CIA port for handle serial lines
		and	#%11000000
		cmp	#%11000000		;DAT+CLK = high?
    ELSEIF target_platform == 264
		lda	$01			;CPU port for handle serial lines
		and	#%11000000
		cmp	#%11000000		;DAT+CLK = high?
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

    IF target_platform == 20
		lda	#%11011100			;Release CLK, DAT
		sta	$912c
		jsr	_wait6
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#def_cia_vicbank | %00000000	;Release CLK, DAT (ATN)
		sta	$dd00
		jsr	_wait6
    ELSEIF target_platform == 264
		lda	#%00001000			;Cas.Mtr Off, Release CLK, DAT (ATN)
		sta	$01
		jsr	_wait6
    ENDIF

$$recvcyc	jsr	bytereceiver
		sta	screen_addr,y
		iny
		bne	$$recvcyc

		lda	$$datastart
		ldy	#0
		jsr	datachecker			;Check received BYTEs
		bcs	$$exittestcyc
		jmp	$$commtestcycle

$$statexit
    IF target_platform == 20
		lda	#%11011100			;Release CLK, DAT
		sta	$912c
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#def_cia_vicbank | %00000000	;Release CLK, DAT (ATN)
		sta	$dd00
    ELSEIF target_platform == 264
		lda	#%00001000			;Cas.Mtr Off, Release CLK, DAT (ATN)
		sta	$01
    ENDIF
		jsr	rom_primm
		BYT	ascii_up,ascii_return,"EXIT, GET DRV STATUS:",ascii_return,0
		ldx	#5
		jsr	wait_frames
		jsr	sd2i_printstatus
		lda	#0
		sta	z_ndx			;Clear keyboard buffer
$$exit		jmp	program_exit

$$datastart	BYT	$00
$$data		BYT	$00

;---	Send BYTE to drive:
bytesender
    IF target_platform == 20
		sta	z_eal
		ldx	#3
$$bytesender_cy	lda	#%11011110			;Drive CLK
		lsr	z_eal
		bcs	$$bitset1
		lda	#%11111110			;Drive CLK + DAT, if sended bit = 0
$$bitset1	sta	$912c				;VIA2 PCR
		jsr	_wait0
		lda	#%11011100			;Release CLK
		lsr	z_eal
		bcs	$$bitset2
		lda	#%11111100			;Release CLK, Drive DAT, if sended bit = 0
$$bitset2	sta	$912c				;VIA2 PCR
		jsr	_wait0
		dex
		bpl	$$bytesender_cy
		rts
    ELSEIF (target_platform == 64) || (target_platform == 128)
		sta	z_eal
		ldx	#3
$$bytesender_cy	lda	#def_cia_vicbank | %00010000	;Drive CLK
		lsr	z_eal
		bcs	$$bitset1
		lda	#def_cia_vicbank | %00110000	;Drive CLK + DAT, if sended bit = 0
$$bitset1	sta	$dd00
		jsr	_wait0
		lda	#def_cia_vicbank | %00000000	;Release CLK
		lsr	z_eal
		bcs	$$bitset2
		lda	#def_cia_vicbank | %00100000	;Release CLK, Drive DAT, if sended bit = 0
$$bitset2	sta	$dd00
		jsr	_wait0
		dex
		bpl	$$bytesender_cy
		rts
    ELSEIF target_platform == 264
		eor	#%11111111		;Inverted drive of DAT line
		sta	z_eal
		ldx	#3
$$bytesender_cy	lda	#%00000101		;Cas.Mtr Off, Drive CLK
		lsr	z_eal
		rol	a			;1 bit to DAT
		sta	$01			;Drive lines
		jsr	_wait2
		lda	#%00000100		;Cas.Mtr Off, Release CLK
		lsr	z_eal
		rol	a			;1 bit to DAT
		sta	$01
		;jsr	_wait0
		nop
		nop
		nop
		;nop
		;nop
		;nop
		bit	$00
		dex
		bpl	$$bytesender_cy
		;jsr	_wait0
		jmp	_wait6
    ENDIF

;---	Receive BYTE from drive:
bytereceiver
    IF target_platform == 20
;%11011100 DAT HiZ CLK HiZ
;%11111100 DAT Lo  CLK HiZ
;%11011110 DAT HiZ CLK Lo
;%11111110 DAT Lo  CLK Lo
		ldx	#%11011110		;Drive CLK
		lda	$911f			;Read B0
		stx	$912c
		lsr	a
		lsr	a
		ror	z_eal
		jsr	_wait0
		ldx	#%11011100		;Release CLK
		lda	$911f			;Read B1
		stx	$912c
		lsr	a
		lsr	a
		ror	z_eal
		jsr	_wait0
		ldx	#%11011110		;Drive CLK
		lda	$911f			;Read B2
		stx	$912c
		lsr	a
		lsr	a
		ror	z_eal
		jsr	_wait0
		ldx	#%11011100		;Release CLK
		lda	$911f			;Read B3
		stx	$912c
		lsr	a
		lsr	a
		ror	z_eal
		jsr	_wait0
		ldx	#%11011110		;Drive CLK
		lda	$911f			;Read B4
		stx	$912c
		lsr	a
		lsr	a
		ror	z_eal
		jsr	_wait0
		ldx	#%11011100		;Release CLK
		lda	$911f			;Read B5
		stx	$912c
		lsr	a
		lsr	a
		ror	z_eal
		jsr	_wait0
		ldx	#%11011110		;Drive CLK
		lda	$911f			;Read B6
		stx	$912c
		lsr	a
		lsr	a
		ror	z_eal
		jsr	_wait0
		ldx	#%11011100		;Release CLK
		lda	$911f			;Read B7
		stx	$912c
		lsr	a
		lsr	a
		ror	z_eal
		lda	z_eal
		rts
    ELSEIF (target_platform == 64) || (target_platform == 128)
		ldx	#def_cia_vicbank | %00010000	;Drive CLK
		lda	$dd00				;Read B0
		stx	$dd00
		asl	a
		ror	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00000000	;Release CLK
		lda	$dd00				;Read B1
		stx	$dd00
		asl	a
		ror	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00010000	;Drive CLK
		lda	$dd00				;Read B2
		stx	$dd00
		asl	a
		ror	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00000000	;Release CLK
		lda	$dd00				;Read B3
		stx	$dd00
		asl	a
		ror	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00010000	;Drive CLK
		lda	$dd00				;Read B4
		stx	$dd00
		asl	a
		ror	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00000000	;Release CLK
		lda	$dd00				;Read B5
		stx	$dd00
		asl	a
		ror	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00010000	;Drive CLK
		lda	$dd00				;Read B6
		stx	$dd00
		asl	a
		ror	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00000000	;Release CLK
		lda	$dd00				;Read B7
		stx	$dd00
		asl	a
		ror	z_eal
		lda	z_eal
		rts
    ELSEIF target_platform == 264
		ldx	#%00001010		;Drive CLK
		lda	$01			;Read B0
		stx	$01
		asl	a
		ror	z_eal
		jsr	_wait3
		ldx	#%00001000		;Release CLK
		lda	$01			;Read B1
		stx	$01
		asl	a
		ror	z_eal
		jsr	_wait3
		ldx	#%00001010		;Drive CLK
		lda	$01			;Read B2
		stx	$01
		asl	a
		ror	z_eal
		jsr	_wait3
		ldx	#%00001000		;Release CLK
		lda	$01			;Read B3
		stx	$01
		asl	a
		ror	z_eal
		jsr	_wait3
		ldx	#%00001010		;Drive CLK
		lda	$01			;Read B4
		stx	$01
		asl	a
		ror	z_eal
		jsr	_wait3
		ldx	#%00001000		;Release CLK
		lda	$01			;Read B5
		stx	$01
		asl	a
		ror	z_eal
		jsr	_wait3
		ldx	#%00001010		;Drive CLK
		lda	$01			;Read B6
		stx	$01
		asl	a
		ror	z_eal
		jsr	_wait3
		ldx	#%00001000		;Release CLK
		lda	$01			;Read B7
		stx	$01
		asl	a
		ror	z_eal
		lda	z_eal
		jsr	_wait3
		jmp	_wait6
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
_drivecode	BINCLUDE "sr1b-pio-drive.bin"
_drivecode_end
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE	"../common/datachecker.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/waitkey.asm"
	INCLUDE	"../common/waittime.asm"
;------------------------------------------------------------------------------
