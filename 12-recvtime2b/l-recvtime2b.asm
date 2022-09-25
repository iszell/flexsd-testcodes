;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Receive time test, 2bit, computer side
;---	USND2 command on drive side, preferred communication method
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"recvtime2b-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC RECV TIME 2BIT:"
		BYT	ascii_return,"USND2 COM., BYTES:",0
		ldx	#lo(def_blockno2)
		lda	#hi(def_blockno2)
		jsr	bas_linprt

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
		BYT	ascii_return,ascii_return,"ONLY ONE DEVICE ALLOWED",0
		jmp	$$exit
$$onlyone	jsr	rom_primm
		BYT	ascii_return,ascii_return,"SD2IEC UNIT NO: #",0
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
		sta	$$datastart
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

$$nokeypressed	lda	#def_blockno2-1
		jsr	bytesender		;CONTINUE

    IF target_platform = 20
		lda	#%11011100		;Release CLK, DAT
		sta	$912c
$$waitready	lda	#%00000011		;DAT/CLK remains
		and	$911f
		cmp	#%00000001		;DAT=Lo, CLK=Hi?
		bne	$$waitready
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#def_cia_vicbank | %00000000	;Release ATN, CLK, DAT
		sta	$dd00
$$waitready	lda	#%11000000		;DAT/CLK remains
		and	$dd00
		cmp	#%01000000		;DAT=Lo, CLK=Hi?
		bne	$$waitready
    ELSEIF target_platform = 264
		lda	#%00001000		;Cas.Mtr Off, Release ATN, CLK, DAT
		sta	$01
$$waitready	lda	#%11000000		;DAT/CLK remains
		and	$01
		cmp	#%01000000		;DAT=Lo, CLK=Hi?
		bne	$$waitready
    ENDIF

		lda	$$bytereceivr_e
		pha
		lda	#$60			;RTS opcode
		sta	$$bytereceivr_e
		jsr	$$bytereceiver		;Receive "start" BYTE
		sta	screen_addr+$102
		lda	#" "
		sta	screen_addr+$101
		sta	screen_addr+$103
		pla
		sta	$$bytereceivr_e

		jsr	wait_for_top

$$bytereceiver
    IF target_platform = 20
		ldx	#%10000000		;ATN drive bit
		ldy	#%00000000		;ATN drive bit
$$bytereceivr_c	lda	$911f			;Read B10
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
		lda	z_eal
    ELSEIF (target_platform = 64) || (target_platform = 128)
		ldx	#def_cia_vicbank | %00001000	;Drive ATN
		ldy	#def_cia_vicbank | %00000000	;Release ATN
$$bytereceivr_c	lda	$dd00				;Read B10
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
    ELSEIF target_platform = 264
		ldx	#%00001100		;ATN Drive bit
		ldy	#%00001000		;ATN Release bit
$$bytereceivr_c	lda	$01			;Read B10
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
    ENDIF
$$bytereceivr_e	sta	screen_addr+(256-def_blockno2)	;Store received BYTE
		inc	$$bytereceivr_e+1
		bne	$$bytereceivr_c
		lda	#256-def_blockno2
		sta	$$bytereceivr_e+1

		jsr	set_rastertime
		ldy	#256-def_blockno2
		lda	$$datastart
		inc	$$datastart
		jsr	datachecker		;Check received BYTEs
		bcs	$$comperror
		jsr	unset_rastertime
		jsr	unset_rastertime
		jmp	$$commtestcycle
$$comperror	jmp	$$exittestcyc

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


;---	Send BYTE to drive:
bytesender
    IF target_platform = 20
		tax
		sty	z_eal
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%10000000		;ATN drive bit
		sta	$912c			;Set CLK (B1) / DAT (B0) lines
		sty	$911f			;ATN drive
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%00000000		;ATN drive bit
		sta	$912c			;Set CLK (B3) / DAT (B2) lines
		sty	$911f			;ATN release
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%10000000		;ATN drive bit
		sta	$912c			;Set CLK (B5) / DAT (B4) lines
		sty	$911f			;ATN drive
		txa
		lsr	a
		lsr	a
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%00000000		;ATN drive bit
		sta	$912c			;Set CLK (B7) / DAT (B6) lines
		sty	$911f			;ATN release
		ldy	z_eal
		rts
$$clkdattable	BYT	%11111110		;DAT Low / CLK Low
		BYT	%11011110		;DAT HiZ / CLK Low
		BYT	%11111100		;DAT Low / CLK HiZ
		BYT	%11011100		;DAT HiZ / CLK HiZ
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
		sta	$01			;B10 to CLK/DAT, Drive ATN
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011		;B32
		ora	#%00001000		;Cas.Mtr Off, Release ATN
		sta	$01			;B32 to CLK/DAT, Release ATN
		txa
		lsr	a
		lsr	a
		tax
		and	#%00000011		;B54
		ora	#%00001100		;Cas.Mtr Off, Drive ATN
		sta	$01			;B54 to CLK/DAT, Drive ATN
		txa
		lsr	a
		lsr	a
		and	#%00000011		;B76
		ora	#%00001000		;Cas.Mtr Off, Release ATN
		sta	$01			;B76 to CLK/DAT, Release ATN
		rts
    ENDIF
;------------------------------------------------------------------------------
;---	Wait for screen TOP position and rastertime set / clear routines:

    IF target_platform = 20
wait_for_top	sei
		lda	$9004
		cmp	#def_rasterpos >> 1
		bne	wait_for_top
set_rastertime	lda	$900f
		and	#%11111000
		sta	$$set+1
		ldx	$900f
		inx
		txa
		and	#%00000111
$$set		ora	#%00000000
		sta	$900f
		cli
		rts
unset_rastertime
		lda	$900f
		and	#%11111000
		sta	$$set+1
		ldx	$900f
		dex
		txa
		and	#%00000111
$$set		ora	#%00000000
		sta	$900f
		rts
    ELSEIF target_platform = 64
wait_for_top	sei
		lda	$d011
		and	#%10000000
		cmp	#((def_rasterpos >> 1) & %10000000)
		bne	wait_for_top
		lda	$d012
		cmp	#lo(def_rasterpos)
		bne	wait_for_top
set_rastertime	dec	$d020
		cli
		rts
unset_rastertime
		inc	$d020
		rts
    ELSEIF target_platform = 264
wait_for_top	lda	$ff1c
		and	#1
		cmp	#hi(def_rasterpos)
		bne	wait_for_top
		lda	$ff1d
		cmp	#lo(def_rasterpos)
		bne	wait_for_top
set_rastertime	inc	$ff19
		rts
unset_rastertime
		dec	$ff19
		rts
    ELSEIF target_platform = 128
wait_for_top	lda	$d011
		and	#%10000000
		cmp	#((def_rasterpos >> 1) & %10000000)
		bne	wait_for_top
		lda	$d012
		cmp	#lo(def_rasterpos)
		bne	wait_for_top
set_rastertime	dec	$d020
		rts
unset_rastertime
		inc	$d020
		rts
    ENDIF
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode
	BINCLUDE "recvtime2b-drive.prg"
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
	INCLUDE	"../common/waittime.asm"
;------------------------------------------------------------------------------
