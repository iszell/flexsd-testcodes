;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.10.10.+ by BSZ
;---	File Load benchmark, computer side
;---	240325+: Testfile changed
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"../common/len_chks.asm"
	INCLUDE	"benchmark-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,"SD2IEC MEGABYTES READ BENCHMARK:",0
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
$$vcpuready	jsr	rom_primm
		BYT	ascii_return,"DOWNLOAD CODE TO DRV",0
		jsr	sd2i_writememory
		ADR	_drivecode
		ADR	_drivecode_end-_drivecode
		ADR	drivecode_start

		jsr	rom_primm
		BYT	ascii_return
		BYT	ascii_return,"BCHMRK-254:",0
		jsr	benchmark
		jsr	rom_primm
		BYT	ascii_return,"BCHMRK-256:",0
		jsr	benchmark
		jsr	rom_primm
		BYT	ascii_return,"SEEK TIME: ",0
		jsr	seektest

		jsr	rom_primm
		BYT	ascii_return,ascii_return,"EXIT, GET DRV STATUS:",ascii_return,0
		ldx	#5
		jsr	wait_frames
		jsr	sd2i_printstatus

		jsr	rom_primm
		BYT	ascii_return,"SEEK PARAMS: ",0
		jsr	sd2i_readmemory
		ADR	drv_chnlparsave
		ADR	drv_chnlparsave_size
		ADR	_channelparams
		ldy	#0
		ldx	#0
$$chnpars	lda	_channelparams,x
		cmp	$$paramdatas,x
		beq	$$paramok
		iny
$$paramok	jsr	mon_puthex
		inx
		cpx	#drv_chnlparsave_size
		bne	$$chnpars
		cpy	#0
		beq	$$paramsmatch
		jsr	rom_primm
		BYT	" <-ERR! OLD FW?",0
		jmp	$$exit
$$paramsmatch	jsr	rom_primm
		BYT	" <-OK!",0

$$exit		lda	#0
		sta	z_ndx			;Clear keyboard buffer
		jmp	program_exit

$$paramdatas	BYT	$02,$ff,$00
		BYT	$00,$ff,$ff
;------------------------------------------------------------------------------
;---	Benchmark:

benchmark	jsr	datainit		;Clear calculated data
		lda	#%11111111
		sta	_stepwait		;First run: always count

		lda	#'E'
		jsr	rom_bsout
		ldx	#lo(drivecode_read)
		ldy	#hi(drivecode_read)
		jsr	sd2i_execmemory_simple
		lda	#'B'
		jsr	rom_bsout
    IF target_platform == 20
		lda	#%00000001		;CLK bit
$$waitstart	bit	$911f			;VIA1 DRA for handle serial lines
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#%01000000		;CLK bit
$$waitstart	bit	$dd00			;CIA port for handle serial lines
    ELSEIF target_platform == 264
		lda	#%01000000		;CLK bit
$$waitstart	bit	$01			;CPU port for handle serial lines
    ENDIF
		bne	$$waitstart		;Wait for CLK Low

		jsr	setinterrupt
$$waitcycle
    IF target_platform == 20
		lda	$911f			;VIA1 DRA
		tax
		and	#%00000001		;CLK
		bne	$$benchmarkend
		txa
		and	#%00000010		;DAT
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	$dd00			;CIA port for handle serial lines
		tax
		and	#%01000000		;CLK
		bne	$$benchmarkend
		txa
		and	#%10000000		;DAT
    ELSEIF target_platform == 264
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

$$benchmarkend	jsr	restoreinterrupt

;	Print file reading time/blockno:
		jsr	rom_primm
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
;---	SEEK time test:
seektest	lda	#'E'
		jsr	rom_bsout
		ldx	#lo(drivecode_seek)
		ldy	#hi(drivecode_seek)
		jsr	sd2i_execmemory_simple
		lda	#'M'
		jsr	rom_bsout

		jsr	setinterrupt

    IF target_platform == 20
		lda	#%00000010		;DAT bit
$$waitstart	bit	$911f			;VIA1 DRA for handle serial lines
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	#%10000000		;DAT bit
$$waitstart	bit	$dd00			;CIA port for handle serial lines
    ELSEIF target_platform == 264
		lda	#%10000000		;DAT bit
$$waitstart	bit	$01			;CPU port for handle serial lines
    ENDIF
		bne	$$waitstart		;Wait for DAT Low

		jsr	datainit		;Clear time
$$waitinterrupt	lda	_time+0
		bne	$$waitinterrupt		;Sync to IRQ

    IF target_platform == 20
		lda	#%11011110		;Drive CLK
		sta	$912c			;VIA2 PCR
		lda	#%11011100		;Release CLK
		sta	$912c			;VIA2 PCR
		lda	#%00000010		;DAT bit
$$waitready	bit	$911f			;VIA1 DRA for handle serial lines
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	$dd00
		ora	#%00010000		;Drive CLK
		sta	$dd00
		and	#%11101111		;Release CLK
		sta	$dd00
		lda	#%10000000		;DAT bit
$$waitready	bit	$dd00			;CIA port for handle serial lines
    ELSEIF target_platform == 264
		lda	#%00001010		;Drive CLK
		sta	$01
		lda	#%00001000		;Release CLK
		sta	$01
		lda	#%10000000		;DAT bit
$$waitready	bit	$01			;CPU port for handle serial lines
    ENDIF
		beq	$$waitready		;Wait for seek ready
		jsr	restoreinterrupt	;Restore interrupt (stop time measure)

;	Print seek time:
		jsr	rom_primm
		BYT	" TM:",0
		ldx	_time+0
		lda	_time+1			;A:X: counted frames
		jmp	bas_linprt
;------------------------------------------------------------------------------
;---	Inicialize calculated data:
datainit	lda	#$ff
		sta	_time+0
		sta	_time+1
		sta	_block+0
		sta	_block+1
		rts
;------------------------------------------------------------------------------
;---	Setting the measure interrupt:

setinterrupt	ldx	#lo(interrupt)
		ldy	#hi(interrupt)
.set		sei
		stx	$0314
		sty	$0315
		cli
		rts

;---	Restore original interrupt:
restoreinterrupt
		ldx	#lo(rom_nirq)
		ldy	#hi(rom_nirq)
		bne	setinterrupt.set
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
;	Previously compiled drivecode binary:
_drivecode
	BINCLUDE "benchmark-drive.bin"
_drivecode_end
;------------------------------------------------------------------------------
_time		BYT	0,0
_block		BYT	0,0
_stepwait	BYT	0
_channelparams	BYT	[drv_chnlparsave_size]0
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_read.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/waittime.asm"
;------------------------------------------------------------------------------
