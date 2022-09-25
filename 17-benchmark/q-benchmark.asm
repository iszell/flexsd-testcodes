;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.10.10.+ by BSZ
;---	File Load benchmark, computer side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"../common/len_chks.asm"
	INCLUDE	"benchmark-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"SD2IEC MEGABYTES READ BENCHMARK:",0
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
$$vcpuready
		jsr	rom_primm
		BYT	ascii_return
		BYT	ascii_return,"BCHMRK-254:",0
		lda	#%00000001
		jsr	benchmark
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,"BCHMRK-256:",0
		lda	#%01000001
		jsr	benchmark
		jsr	printdata
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"EXIT, GET DRV STATUS:",ascii_return,0
		ldx	#5
		jsr	wait_frames
		jsr	sd2i_printstatus
		lda	#0
		sta	z_ndx			;Clear keyboard buffer
$$exit		rts
;------------------------------------------------------------------------------
;---	Benchmark:
;---	A <- B6=0: 254, =1: 256 BYTEs

benchmark	sta	_modebits

		jsr	datainit		;Clear calculated data
		lda	#%11111111
		sta	_stepwait		;First run: always count

		jsr	downloadstartcode	;Download + Start code

		ldx	#lo(interrupt)
		ldy	#hi(interrupt)
		sei
		stx	$0314
		sty	$0315
		cli

$$waitcycle
    IF target_platform = 20
		lda	$911f			;VIA1 DRA
		tax
		and	#%00000001		;CLK
		bne	$$benchmarkend
		txa
		and	#%00000010		;DAT
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	$dd00			;CIA port for handle serial lines
		tax
		and	#%01000000		;CLK
		bne	$$benchmarkend
		txa
		and	#%10000000		;DAT
    ELSEIF target_platform = 264
		lda	$01			;CPU port for handle serial lines
		tax
		and	#%01000000		;CLK
		bne	$$benchmarkend
		txa
		and	#%10000000		;DAT
    ENDIF
		cmp	_stepwait
		beq	$$waitcycle
		sta	_stepwait
		inc	_block+0
		bne	$$ncy
		inc	_block+1
$$ncy		lda	_block+1
		sta	screen_addr+0
		lda	_block+0
		sta	screen_addr+1
		lda	_color
		sta	color_addr+0
		sta	color_addr+1
		jmp	$$waitcycle

$$benchmarkend	sei
		lda	#lo(rom_nirq)
		sta	$0314
		lda	#hi(rom_nirq)
		sta	$0315
		cli
		rts
;------------------------------------------------------------------------------
;---	Inicialize calculated data:
datainit	lda	#$ff
		sta	_time+0
		sta	_time+1
		sta	_block+0
		sta	_block+1
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
		jmp	bas_linprt
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
		lda	#'B'
		jsr	rom_bsout

    IF target_platform = 20
		lda	#%00000001		;CLK bit
$$waitstart	bit	$911f			;VIA1 DRA for handle serial lines
    ELSEIF (target_platform = 64) || (target_platform = 128)
		lda	#%01000000		;CLK bit
$$waitstart	bit	$dd00			;CIA port for handle serial lines
    ELSEIF target_platform = 264
		lda	#%01000000		;CLK bit
$$waitstart	bit	$01			;CPU port for handle serial lines
    ENDIF
		bne	$$waitstart		;Wait for CLK Low
		rts
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode
_modebits
	BINCLUDE "benchmark-drive.prg"
_drivecode_end
;------------------------------------------------------------------------------
_time		BYT	0,0
_block		BYT	0,0
_stepwait	BYT	0
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/waittime.asm"
;------------------------------------------------------------------------------
