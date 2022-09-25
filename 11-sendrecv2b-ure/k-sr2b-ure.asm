;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Send/Receive test, 2bit, computer side
;---	UCDTA/UATCD commands on drive side, reversed bit order,
;---				 preferred communication method
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"sr2b-ure-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_return,ascii_return,"SD2IEC SEND+RECV 2BIT:"
		BYT	ascii_return,"UCDTA/UATCD COMMANDS, PREFERRED METHOD"
		BYT	ascii_return,"REVERSE BIT ORDER",ascii_return,0

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
		lda	#%00000011
		sta	$911f			;Release ATN
		lda	#%11111100		;Dirty hack: all Joy bits + Cas.Sense output and LOW
		sta	$9113			;DDRA
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#def_cia_vicbank | %00000000	;Release ATN, CLK, DAT
		sta	$dd00
		lda	#%00111111			;Only DAT/CLK in input
		sta	$dd02
    ELSEIF target_platform = 264
		lda	#%00001000		;Cas.Mtr Off, Release ATN, CLK, DAT
		sta	$01
    ENDIF

$$commtestcycle
    IF target_platform = 20
		lda	$911f			;VIA1 DRA
		and	#%00000011
		cmp	#%00000011
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
		lda	#%11011100			;Release CLK, DAT
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
		lda	#%10000000		;Normal DDRA restore
		sta	$9113			;DDRA
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#def_cia_vicbank | %00000000	;Release CLK, DAT (ATN)
		sta	$dd00
    ELSEIF target_platform = 264
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
		sty	z_eal
		asl	a
		rol	a
		rol	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%10000000			;ATN drive bit
		sta	$912c				;Set CLK (B6) / DAT (B7) lines
		sty	$911f				;ATN drive
		txa
		rol	a
		rol	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%00000000			;ATN drive bit
		sta	$912c				;Set CLK (B4) / DAT (B5) lines
		sty	$911f				;ATN release
		txa
		rol	a
		rol	a
		tax
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%10000000			;ATN drive bit
		sta	$912c				;Set CLK (B2) / DAT (B3) lines
		sty	$911f				;ATN drive
		txa
		rol	a
		rol	a
		and	#%00000011
		tay
		lda	$$clkdattable,y
		ldy	#%00000000			;ATN drive bit
		sta	$912c				;Set CLK (B0) / DAT (B1) lines
		sty	$911f				;ATN release
		ldy	z_eal
		rts
$$clkdattable	BYT	%11111110			;DAT Low / CLK Low
		BYT	%11111100			;DAT Low / CLK HiZ
		BYT	%11011110			;DAT HiZ / CLK Low
		BYT	%11011100			;DAT HiZ / CLK HiZ
    ELSEIF (target_platform = 64) || (target_platform = 128)
		eor	#%11111111
		tax
		lsr	a
		lsr	a
		and	#%00110000
		ora	#def_cia_vicbank | %00001000	;Set CLK (B6) / DAT (B7), drive ATN
		sta	$dd00
		txa
		and	#%00110000
		ora	#def_cia_vicbank | %00000000	;Set CLK (B4) / DAT (B5), release ATN
		sta	$dd00
		txa
		asl	a
		asl	a
		tax
		and	#%00110000
		ora	#def_cia_vicbank | %00001000	;Set CLK (B2) / DAT (B3), drive ATN
		sta	$dd00
		txa
		asl	a
		asl	a
		and	#%00110000
		ora	#def_cia_vicbank | %00000000	;Set CLK (B0) / DAT (B1), release ATN
		sta	$dd00
		rts
    ELSEIF target_platform = 264
		sta	z_eal
		lda	#%00001100		;Cas.Mtr Off, Drive ATN
		asl	z_eal
		bcs	$$sendodd1
		ora	#%00000001
$$sendodd1	asl	z_eal
		bcs	$$sendeven1
		ora	#%00000010
$$sendeven1	sta	$01			;B76 to CLK/DAT, Drive ATN
		lda	#%00001000		;Cas.Mtr Off, Release ATN
		asl	z_eal
		bcs	$$sendodd2
		ora	#%00000001
$$sendodd2	asl	z_eal
		bcs	$$sendeven2
		ora	#%00000010
$$sendeven2	sta	$01			;B54 to CLK/DAT, Release ATN
		lda	#%00001100		;Cas.Mtr Off, Drive ATN
		asl	z_eal
		bcs	$$sendodd3
		ora	#%00000001
$$sendodd3	asl	z_eal
		bcs	$$sendeven3
		ora	#%00000010
$$sendeven3	sta	$01			;B32 to CLK/DAT, Drive ATN
		lda	#%00001000		;Cas.Mtr Off, Release ATN
		asl	z_eal
		bcs	$$sendodd4
		ora	#%00000001
$$sendodd4	asl	z_eal
		bcs	$$sendeven4
		ora	#%00000010
$$sendeven4	sta	$01			;B10 to CLK/DAT, Release ATN
		rts
    ENDIF

;---	Receive BYTE from drive:
bytereceiver
    IF target_platform = 20
		sty	z_eah
		ldx	#%10000000		;ATN drive bit
		ldy	#%00000000		;ATN drive bit
		lda	$911f			;Read B76
		stx	$911f			;Drive ATN
		asl	a
		asl	a
		eor	$911f			;Read B54
		sty	$911f			;Release ATN
		asl	a
		asl	a
		eor	$911f			;Read B32
		stx	$911f			;Drive ATN
		asl	a
		asl	a
		eor	$911f			;Read B10
		sty	$911f			;Release ATN
		eor	#%10000000
		ldy	z_eah
		rts
    ELSEIF (target_platform = 64) || (target_platform = 128)
		sty	z_eah				;Y save
		ldx	#def_cia_vicbank | %00001000	;Drive ATN
		ldy	#def_cia_vicbank | %00000000	;Release ATN
		lda	$dd00				;Read B76
		stx	$dd00				;Drive ATN
		asl	a
		rol	z_eal
		asl	a
		rol	z_eal
		lda	$dd00				;Read B54
		sty	$dd00				;Release ATN
		asl	a
		rol	z_eal
		asl	a
		rol	z_eal
		lda	$dd00				;Read B32
		stx	$dd00				;Drive ATN
		asl	a
		rol	z_eal
		asl	a
		rol	z_eal
		lda	$dd00				;Read B10
		sty	$dd00				;Release ATN
		asl	a
		rol	z_eal
		asl	a
		rol	z_eal
		lda	z_eal
		ldy	z_eah
		rts
    ELSEIF target_platform = 264
		sty	z_eah
		ldx	#%00001100			;ATN Drive bit
		ldy	#%00001000			;ATN Release bit
		lda	$01
		stx	$01				;Drive ATN
		asl	a
		rol	z_eal
		asl	a
		rol	z_eal
		lda	$01
		sty	$01				;Release ATN
		asl	a
		rol	z_eal
		asl	a
		rol	z_eal
		lda	$01
		stx	$01				;Drive ATN
		asl	a
		rol	z_eal
		asl	a
		rol	z_eal
		lda	$01
		sty	$01				;Release ATN
		asl	a
		rol	z_eal
		asl	a
		rol	z_eal
		lda	z_eal
		ldy	z_eah
		rts
    ENDIF
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode	BINCLUDE "sr2b-ure-drive.prg"
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
