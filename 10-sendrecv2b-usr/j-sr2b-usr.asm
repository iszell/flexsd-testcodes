;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Send/Receive test, 2bit, computer side
;---	USND2/URCV2 commands on drive side, preferred communication method
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"sr2b-usr-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC SEND+RECV 2BIT:"
		BYT	ascii_return,"USND2/URCV2 COMMANDS, PREFERRED METHOD",ascii_return,0

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
		cmp	#%00000011		;DAT+CLK = high?
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	$dd00			;CIA port for handle serial lines
		and	#%11000000
		cmp	#%11000000		;DAT+CLK = high?
    ELSEIF target_platform = 264
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

    IF target_platform = 20
		lda	#%11011100		;Release CLK, DAT
		sta	$912c
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#def_cia_vicbank | %00000000	;Release CLK, DAT (ATN)
		sta	$dd00
    ELSEIF target_platform = 264
		lda	#%00001000		;Cas.Mtr Off, Release CLK, DAT (ATN)
		sta	$01
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
		tax
		sty	z_eal
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%10000000			;ATN drive bit
		sta	$912c				;Set CLK (B1) / DAT (B0) lines
		sty	$911f				;Drive ATN
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%00000000			;ATN drive bit
		sta	$912c				;Set CLK (B3) / DAT (B2) lines
		sty	$911f				;Release ATN
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%10000000			;ATN drive bit
		sta	$912c				;Set CLK (B5) / DAT (B4) lines
		sty	$911f				;Drive ATN
		txa
		lsr	a
		lsr	a
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%00000000			;ATN drive bit
		sta	$912c				;Set CLK (B7) / DAT (B6) lines
		sty	$911f				;Release ATN
		ldy	z_eal
		rts
$$clkdattable	BYT	%11111110			;DAT Low / CLK Low
		BYT	%11011110			;DAT HiZ / CLK Low
		BYT	%11111100			;DAT Low / CLK HiZ
		BYT	%11011100			;DAT HiZ / CLK HiZ
    ELSEIF (target_platform = 64) || (target_platform = 128)
		sty	z_eal
		tax
		and	#%00000011
		tay
		lda	$$atnloclkdat,y
		sta	$dd00
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011
		tay
		lda	$$atnhiclkdat,y
		sta	$dd00
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011
		tay
		lda	$$atnloclkdat,y
		sta	$dd00
		txa
		lsr	a
		lsr	a
		and	#%00000011
		tay
		lda	$$atnhiclkdat,y
		sta	$dd00
		ldy	z_eal
		rts
$$atnloclkdat	BYT	def_cia_vicbank | %00111000	;DAT Low / CLK Low / ATN Low
		BYT	def_cia_vicbank | %00011000	;DAT HiZ / CLK Low / ATN Low
		BYT	def_cia_vicbank | %00101000	;DAT Low / CLK HiZ / ATN Low
		BYT	def_cia_vicbank | %00001000	;DAT HiZ / CLK HiZ / ATN Low
$$atnhiclkdat	BYT	def_cia_vicbank | %00110000	;DAT Low / CLK Low / ATN HiZ
		BYT	def_cia_vicbank | %00010000	;DAT HiZ / CLK Low / ATN HiZ
		BYT	def_cia_vicbank | %00100000	;DAT Low / CLK HiZ / ATN HiZ
		BYT	def_cia_vicbank | %00000000	;DAT HiZ / CLK HiZ / ATN HiZ
    ELSEIF target_platform = 264
		eor	#%11111111		;Inverted drive of CLK/DAT lines
		tax
		and	#%00000011		;B10
		ora	#%00001100		;Cas.Mtr Off, Drive ATN
		sta	$01			;B10 to CLK/DAT
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011		;B32
		ora	#%00001000		;Cas.Mtr Off, Release ATN
		sta	$01			;B32 to CLK/DAT
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011		;B54
		ora	#%00001100		;Cas.Mtr Off, Drive ATN
		sta	$01			;B54 to CLK/DAT
		txa
		lsr	a
		lsr	a
		and	#%00000011		;B76
		ora	#%00001000		;Cas.Mtr Off, Release ATN
		sta	$01			;B76 to CLK/DAT
		rts
    ENDIF

;---	Receive BYTE from drive:
bytereceiver
    IF target_platform = 20
		sty	z_eah
		ldx	#%10000000		;ATN drive bit
		lda	$911f			;Read B10
		stx	$911f			;Drive ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal			;B3210 -> B7654
		ldx	#%00000000		;ATN drive bit
		lda	$911f			;Read B32
		stx	$911f			;Release ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal			;B3210 -> B7654
		ldx	#%10000000		;ATN drive bit
		lda	$911f			;Read B54
		stx	$911f			;Drive ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal			;B543210 -> B765432
		ldx	#%00000000		;ATN drive bit
		lda	$911f			;Read B76
		stx	$911f			;Release ATN
		lsr	a
		ror	z_eal
		lsr	a
		ror	z_eal			;B76543210 -> B76543210
		lda	z_eal
		ldy	z_eah
		rts
    ELSEIF (target_platform = 64) || (target_platform = 128)
		sty	z_eal				;Y save
		ldx	#def_cia_vicbank | %00001000	;Drive ATN
		ldy	#def_cia_vicbank | %00000000	;Release ATN
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
		ldy	z_eal
		rts
    ELSEIF target_platform = 264
		sty	z_eah
		ldx	#%00001100		;ATN Drive bit
		ldy	#%00001000		;ATN Release bit
		lda	$01
		stx	$01			;Drive ATN
		lsr	a
		lsr	a
		eor	$01
		sty	$01			;Release ATN
		lsr	a
		lsr	a
		eor	$01
		stx	$01			;Drive ATN
		lsr	a
		lsr	a
		eor	#%00001110
		eor	$01
		sty	$01			;Release ATN
		ldy	z_eah
		rts
    ENDIF
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode	BINCLUDE "sr2b-usr-drive.prg"
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
