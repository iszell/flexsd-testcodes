;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Send/Receive test, 2bit, computer side
;---	Programmed I/O on drive side, only for testing, not recommended for
;---	  regular use!
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"sr2b-pio-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC SEND+RECV 2BIT:"
    IF target_platform <> 20
		BYT	ascii_return,"PROGRAMMED I/O, NOT RECOMMENDED",ascii_return,0
    ELSE
		BYT	ascii_return,"PIO2B, NOT RECOMMENDED",ascii_return,ascii_up,0
    ENDIF

		jsr	sd2i_scanning_bus
		sta	z_fa				;Set SD2IEC Unit No
		cmp	#0				;Any SD2IEC on the bus?
		bne	$$sd2iecpresent
		jsr	rom_primm
		BYT	ascii_return,"NO SD2IEC DETECTED",0
		jmp	$$exit
$$sd2iecpresent	cpx	#1				;Only one device connected to serial bus?
		beq	$$onlyone
		jsr	rom_primm
		BYT	ascii_return,"ONLY ONE DEVICE ALLOWED",0
		jmp	$$exit
$$onlyone	jsr	rom_primm
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
		sta	z_ndx		;Clear Interrupt's keyboard buffer
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
		lda	#%11011100		;Release CLK, DAT
		sta	$912c
		jsr	_wait6
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#def_cia_vicbank | %00000000	;Release CLK, DAT (ATN)
		sta	$dd00
		jsr	_wait6
    ELSEIF target_platform == 264
		lda	#%00001000		;Cas.Mtr Off, Release CLK, DAT (ATN)
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
    IF target_platform == 20
		lda	#%11011100		;Release CLK, DAT
		sta	$912c
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#def_cia_vicbank | %00000000	;Release CLK, DAT (ATN)
		sta	$dd00
    ELSEIF target_platform == 264
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
$$exit		jmp	program_exit

$$datastart	BYT	$00
$$data		BYT	$00


;---	Send BYTE to drive:
bytesender
    IF target_platform == 20
		tax
		sty	z_eal
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%10000000			;ATN drive bit
		sta	$912c				;Set CLK (B0) / DAT (B1) lines
		sty	$911f				;ATN drive
		jsr	_wait1
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%00000000			;ATN drive bit
		sta	$912c				;Set CLK (B2) / DAT (B3) lines
		sty	$911f				;ATN release
		jsr	_wait1
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%10000000			;ATN drive bit
		sta	$912c				;Set CLK (B4) / DAT (B5) lines
		sty	$911f				;ATN drive
		jsr	_wait1
		txa
		lsr	a
		lsr	a
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%00000000			;ATN drive bit
		sta	$912c				;Set CLK (B6) / DAT (B7) lines
		sty	$911f				;ATN release
		;jsr	_wait1
		ldy	z_eal
		rts
$$clkdattable	BYT	%11111110			;DAT Low / CLK Low
		BYT	%11111100			;DAT Low / CLK HiZ
		BYT	%11011110			;DAT HiZ / CLK Low
		BYT	%11011100			;DAT HiZ / CLK HiZ
    ELSEIF (target_platform == 64) || (target_platform == 128)
		eor	#%11111111
		sta	z_eal
		asl	a
		asl	a
		sta	z_eah
		asl	a
		asl	a
		and	#%00110000
		ora	#def_cia_vicbank | %00001000	;Set CLK (B0) / DAT (B1), drive ATN
		sta	$dd00
		jsr	_wait0
		lda	z_eah
		and	#%00110000
		ora	#def_cia_vicbank | %00000000	;Set CLK (B2) / DAT (B3), release ATN
		sta	$dd00
		jsr	_wait0
		lda	z_eal
		and	#%00110000
		ora	#def_cia_vicbank | %00001000	;Set CLK (B4) / DAT (B5), drive ATN
		sta	$dd00
		lda	z_eal
		lsr	a
		lsr	a
		and	#%00110000
		ora	#def_cia_vicbank | %00000000	;Set CLK (B6) / DA7 (B5), release ATN
		sta	$dd00
		rts
    ELSEIF target_platform == 264
		eor	#%11111111		;Inverted drive of CLK/DAT lines
		sta	z_eal
		lda	#%00000000
		lsr	z_eal
		rol	a
		lsr	z_eal
		rol	a			;2 bits to B10
		ora	#%00001100		;Cas.Mtr Off, Drive ATN
		sta	$01			;B10 to DAT/CLK
		jsr	_wait0
		lda	#%00000000
		lsr	z_eal
		rol	a
		lsr	z_eal
		rol	a			;2 bits to B10
		ora	#%00001000		;Cas.Mtr Off, Release ATN
		sta	$01			;B32 to DAT/CLK
		jsr	_wait0
		lda	#%00000000
		lsr	z_eal
		rol	a
		lsr	z_eal
		rol	a			;2 bits to B10
		ora	#%00001100		;Cas.Mtr Off, Drive ATN
		sta	$01			;B54 to DAT/CLK
		jsr	_wait0
		lda	#%00000000
		lsr	z_eal
		rol	a
		lsr	z_eal
		rol	a			;2 bits to B10
		ora	#%00001000		;Cas.Mtr Off, Release ATN
		sta	$01			;B76 to DAT/CLK
		jmp	_wait5
    ENDIF

;---	Receive BYTE from drive:
bytereceiver
    IF target_platform == 20
;;%11011100 DAT HiZ CLK HiZ
;;%11111100 DAT Lo  CLK HiZ
;;%11011110 DAT HiZ CLK Lo
;;%11111110 DAT Lo  CLK Lo
		ldx	#%10000000			;ATN drive bit
		lda	$911f				;Read B10
		stx	$911f				;Drive ATN
		lsr	a
		ror	a
		ror	a				;B10 -> B76
		and	#%11000000
		sta	z_eal
		jsr	_wait6
		ldx	#%00000000			;ATN drive bit
		lda	$911f				;Read B32
		stx	$911f				;Release ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal				;B3210 -> B7654
		jsr	_wait6
		ldx	#%10000000			;ATN drive bit
		lda	$911f				;Read B54
		stx	$911f				;Drive ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal				;B543210 -> B765432
		jsr	_wait6
		ldx	#%00000000			;ATN drive bit
		lda	$911f				;Read B76
		stx	$911f				;Release ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal				;B76543210 -> B76543210
		lda	z_eal
		jsr	_wait6
		rts
    ELSEIF (target_platform == 64) || (target_platform == 128)
		ldx	#def_cia_vicbank | %00001000	;ATN drive, CLK/DAT release
		lda	$dd00				;Read B10
		stx	$dd00				;Drive ATN
		lsr	a
		lsr	a
		and	#%00110000
		sta	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00000000	;ATN release, CLK/DAT release
		lda	$dd00				;Read B32
		stx	$dd00				;Release ATN
		and	#%11000000
		ora	z_eal
		lsr	a
		lsr	a
		sta	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00001000	;ATN drive, CLK/DAT release
		lda	$dd00				;Read B54
		stx	$dd00				;Drive ATN
		and	#%11000000
		ora	z_eal
		lsr	a
		lsr	a
		sta	z_eal
		jsr	_wait0
		ldx	#def_cia_vicbank | %00000000	;ATN release, CLK/DAT release
		lda	$dd00				;Read B32
		stx	$dd00				;Release ATN
		and	#%11000000
		ora	z_eal
		rts
    ELSEIF target_platform == 264
		ldx	#%00001100			;ATN drive bit
		lda	$01				;Read B10
		stx	$01				;Drive ATN
		lsr	a
		lsr	a
		and	#%00110000
		sta	z_eal
		jsr	_wait1_5
		ldx	#%00001000			;ATN release bit
		lda	$01				;Read B32
		stx	$01				;Release ATN
		and	#%11000000
		ora	z_eal
		lsr	a
		lsr	a
		sta	z_eal
		jsr	_wait1_5
		ldx	#%00001100			;ATN drive bit
		lda	$01				;Read B54
		stx	$01				;Drive ATN
		and	#%11000000
		ora	z_eal
		lsr	a
		lsr	a
		sta	z_eal
		jsr	_wait1_5
		ldx	#%00001000			;ATN release bit
		lda	$01				;Read B76
		stx	$01				;Release ATN
		and	#%11000000
		ora	z_eal
		jsr	_wait1_5
		jmp	_wait2
    ENDIF

;---	Waits:
_wait6		nop
_wait5		nop
_wait4		nop
_wait3		nop
_wait2		nop
_wait1		nop
_wait0		rts
_wait1_5	bit	$00
		rts
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode	BINCLUDE "sr2b-pio-drive.bin"
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
