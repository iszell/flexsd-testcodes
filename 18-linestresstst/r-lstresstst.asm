;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Serial lines stress test, computer side
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"lstresstst-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,"SD2IEC LINES STRESS TEST:",0

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

$$vcpuready	lda	#0
		sta	_errorno+0
		sta	_errorno+1			;Clear Error number
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"  SELECT LINE(S):",ascii_return
		BYT	ascii_return,ascii_rvson,"[A]",ascii_rvsoff,": ATN"
		BYT	ascii_return,ascii_rvson,"[C]",ascii_rvsoff,": CLK"
		BYT	ascii_return,ascii_rvson,"[D]",ascii_rvsoff,": DAT"
		BYT	ascii_return,ascii_rvson,"[F]",ascii_rvsoff,": ATN+CLK"
		BYT	ascii_return,ascii_rvson,"[G]",ascii_rvsoff,": ATN+DAT"
		BYT	ascii_return,ascii_rvson,"[H]",ascii_rvsoff,": !ATN+CLK"
		BYT	ascii_return,ascii_rvson,"[J]",ascii_rvsoff,": !ATN+DAT"
		BYT	ascii_return,ascii_rvson,"[SPACE]",ascii_rvsoff,": EXIT"
		BYT	ascii_return,ascii_return,"# CHOOSE ",ascii_rvson,"[ACDFGHJ]",ascii_rvsoff,":",0
$$waitkeycyc	jsr	wait_keypress			;Wait any key
		sta	_pressedbutton			;Save

		cmp	#'A'				;ATN line?
		bne	$$pressed_nota
		ldx	#%10000000			;ATN bit
		ldy	#%11111100			;Default: CLK+DAT = Low
    IF target_platform == 20
		lda	#%00000011			;DAT+CLK check
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#%11000000			;DAT+CLK check
    ELSEIF target_platform == 264
		lda	#%11000000			;DAT+CLK check
    ENDIF
		bne	$$download			;BRA

$$pressed_nota	cmp	#'C'				;CLK line?
		bne	$$pressed_notc
		ldx	#%00000001			;CLK bit
		ldy	#%11111100			;Default: CLK+DAT = Low
		bne	$$datchk			;DAT check

$$pressed_notc	cmp	#'D'				;DAT line?
		bne	$$pressed_notd
		ldx	#%00000010			;DAT bit
		ldy	#%11111100			;Default: CLK+DAT = Low
$$clkchk
    IF target_platform == 20
		lda	#%00000001			;CLK check
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#%01000000			;CLK check
    ELSEIF target_platform == 264
		lda	#%01000000			;CLK check
    ENDIF
		bne	$$download			;BRA

$$pressed_notd	cmp	#'F'				;ATN+CLK lines?
		bne	$$pressed_notf
		ldx	#%10000001			;ATN+CLK bit
		ldy	#%01111100			;Default: ATN+CLK+DAT = Lo
		bne	$$datchk			;BRA DAT check

$$pressed_notf	cmp	#'G'				;ATN+DAT lines?
		bne	$$pressed_notg
		ldx	#%10000010			;ATN+DAT bit
		ldy	#%01111100			;Default: ATN+CLK+DAT = Lo
		bne	$$clkchk			;BRA CLK check

$$pressed_notg	cmp	#'H'				;!ATN+CLK lines?
		bne	$$pressed_noth
		ldx	#%10000001			;ATN+CLK bit
		ldy	#%11111100			;Default: ATN HiZ, CLK+DAT = Lo
		bne	$$datchk			;BRA DAT check

$$pressed_noth	cmp	#'J'				;!ATN+DAT lines?
		bne	$$pressed_notj
		ldx	#%10000010			;ATN+DAT bit
		ldy	#%11111100			;Default: ATN HiZ, CLK+DAT = Lo
		bne	$$clkchk			;BRA CLK check

$$pressed_notj	cmp	#' '
		bne	$$waitkeycyc
		jsr	rom_primm
		BYT	ascii_return,"EXIT...",0
$$exit		jmp	program_exit



$$datchk
    IF target_platform == 20
		lda	#%00000010			;DAT check
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#%10000000			;DAT check
    ELSEIF target_platform == 264
		lda	#%10000000			;DAT check
    ENDIF

$$download	stx	_drivecode+0			;Mode patch to drivecode
		sty	_drivecode+1
		sta	_linesmask			;Save Check pattern
		lda	_pressedbutton
		jsr	rom_bsout			;Print selected
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"DOWNLOAD CODE TO DRV",0
		jsr	sd2i_writememory
		ADR	_drivecode
		ADR	_drivecode_end-_drivecode
		ADR	drivecode_start

		jsr	rom_primm
		BYT	ascii_return,"START CODE IN DRV",0
		ldx	#lo(drivecode_go)
		ldy	#hi(drivecode_go)
		jsr	sd2i_execmemory_simple

		jsr	rom_primm
		BYT	ascii_return,"# PRESS ",ascii_rvson,"[NEXT]",ascii_rvsoff," BUTTON ON DRIVE TO EXIT",0
		ldx	#10
		jsr	wait_frames

$$testcycle	jsr	getlines
		and	_linesmask
		beq	$$testcycle			;Test runs as long as the tested line(s) is (are) low

		lda	_readedlines
		pha
		jsr	getlines			;Read again
		and	_linesmask
		bne	$$selector			;Go back to select
		inc	_errorno+0
		bne	$$nohiinc
		inc	_errorno+1
$$nohiinc	jsr	rom_primm
		BYT	ascii_return,"LINE ERROR: ",0
		ldx	_errorno+0
		lda	_errorno+1
		jsr	bas_linprt
		jsr	rom_primm
		BYT	" ($",0
		pla
		jsr	mon_puthex
		lda	#'/'
		jsr	rom_bsout
		lda	_pressedbutton
		jsr	rom_bsout
		lda	#')'
		jsr	rom_bsout			;" ($IN/x)"
		jmp	$$testcycle

$$selector	pla
		jsr	$$statexit			;Print status
		jmp	$$vcpuready			;Go back to select

$$statexit	jsr	rom_primm
		BYT	ascii_return,"EXIT, GET DRV STATUS:",ascii_return,0
		ldx	#5
		jsr	wait_frames
		jmp	sd2i_printstatus
;------------------------------------------------------------------------------
;---	Read and mask CLK/DAT line state:
getlines
    IF target_platform == 20
		lda	$911f			;VIA1 DRA
		and	#%00000011
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	$dd00			;CIA port for handle serial lines
		and	#%11000000
    ELSEIF target_platform == 264
		lda	$01			;CPU port for handle serial lines
		and	#%11000000
    ENDIF
		sta	_readedlines
		rts
;------------------------------------------------------------------------------
_pressedbutton	BYT	0
_linesmask	BYT	0
_readedlines	BYT	0
_errorno	ADR	0
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode
	BINCLUDE "lstresstst-drive.bin"
_drivecode_end
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/waittime.asm"
	INCLUDE	"../common/waitkey.asm"
;------------------------------------------------------------------------------
