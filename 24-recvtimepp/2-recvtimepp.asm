;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2024.08.11.+ by BSZ
;---	Receive time test, parallel port, computer side
;---	PPDRD/PPDWR/PPACK/PPWAI commands on drive side
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
	INCLUDE	"../common/hosthwmacros.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"recvtimepp-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,ascii_return,ascii_return
    IF target_platform == 20
		BYT	ascii_return,"SD2IEC RECV TIME, PP:"
		BYT	ascii_return,"PPXXX COM., BYTES:",0
    ELSE
		BYT	ascii_return,"SD2IEC RECV TIME, PARALLEL PORT:"
		BYT	ascii_return,"PPDRD/PPDWR/PPACK/PPWAI COM., BYTES:",0
    ENDIF
		ldx	#lo(def_blockno4)
		lda	#hi(def_blockno4)
		jsr	bas_linprt

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
$$vcpuready	lda	_vcpu_version			;VCPU version + bus type
		and	#%11100000			;Bus type remain
		cmp	#4<<5				;SER+PAR?
		beq	$$vcpuparallel
		cmp	#5<<5				;FASTSER+PAR?
		beq	$$vcpuparallel
		jsr	rom_primm
		BYT	ascii_return,"DRIVE NOT SUPPORT PARALLEL PORT",0
		jmp	$$exit
$$vcpuparallel	jsr	rom_primm
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

		pp_hwinit			;Inicialize HW

		jsr	checkparallellink
		bcc	$$parlinkok
		pp_hwdeinit			;Reset HW to default state
		jmp	$$exit

$$parlinkok	jsr	rom_primm
    IF target_platform == 128
		BYT	ascii_return,"# ",ascii_rvson,"[SHIFT]",ascii_rvsoff,": 2 MHZ MODE"
    ENDIF
		BYT	ascii_return,"# ",ascii_rvson,"[SPACE]",ascii_rvsoff,": EXIT"
    IF target_platform <> 128
		BYT	ascii_return
    ENDIF
		BYT	ascii_return,ascii_return,ascii_return
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,0
		jsr	fillscreenfordata
		ldx	#10
		jsr	wait_frames

		lda	#0
		sta	$$datastart

		lda	#0
		sta	z_ndx		;Clear Interrupt's keyboard buffer

$$commtestcycle	pp_porttoout			;Switch parport to output
		lda	z_ndx			;Any key pressed?
		beq	$$nokeypressed
$$exittestcyc	sei
		ser_starttransfer		;Transfer start
		lda	#$00			;EXIT
		pp_writeport			;Send data
		cli
		jsr	rom_primm
		BYT	ascii_return,"COMM TEST END.",0
		jmp	$$statexit

$$nokeypressed	sei
		ser_starttransfer		;Transfer start
		lda	#def_blockno4-1
		pp_writeport			;Send data
		pp_porttoin			;Switch parport to input

		jsr	wait_for_top

    IF target_platform == 128
		lda	#%00000001
		bit	z_shflag
		beq	$$noshiftpress
		;lda	#%00000001
		sta	$d030			;2 MHz mode ON
$$noshiftpress
    ENDIF

$$bytereceivr_c	pp_readport
$$bytereceivr_e	sta	screen_addr+(256-def_blockno4)	;Store received BYTE
		inc	$$bytereceivr_e+1
		bne	$$bytereceivr_c

    IF target_platform == 128
		lda	#%00000000
		sta	$d030			;2 MHz mode OFF
    ENDIF
		lda	#256-def_blockno4
		sta	$$bytereceivr_e+1
		jsr	set_rastertime

		cli
		ldy	#256-def_blockno4
		lda	$$datastart
		inc	$$datastart
		jsr	datachecker		;Check received BYTEs
		bcs	$$comperror
		jsr	unset_rastertime
		jsr	unset_rastertime
		jmp	$$commtestcycle
$$comperror	jmp	$$exittestcyc

$$statexit
		pp_hwdeinit
		jsr	rom_primm
		BYT	ascii_up,ascii_return,"EXIT, GET DRV STATUS:",ascii_return
    IF target_platform == 128
		BYT	ascii_esc,"Q"
    ENDIF
		BYT	0

		ldx	#5
		jsr	wait_frames
		jsr	sd2i_printstatus
		lda	#0
		sta	z_ndx			;Clear keyboard buffer

$$exit		jmp	program_exit

$$datastart	BYT	$00
;------------------------------------------------------------------------------
;---	Wait for screen TOP position and rastertime set / clear routines:

    IF target_platform == 20
wait_for_top	lda	$9004
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
    ELSEIF target_platform == 64
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
    ELSEIF target_platform == 264
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
    ELSEIF target_platform == 128
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
;---	Check parallel link:
checkparallellink

		sei
		jsr	rom_primm
		BYT	ascii_return,"CHECK PARALLEL LINK:",0

		pp_porttoin			;Switch parport to input
		ser_waitclklo			;Wait for CLK line Low
		pp_clrdrwp			;Clear DRW flag
		ser_setdat 0			;Set DAT to low
		pp_chkdrwp			;Check DRW flag
		beq	$$noparallel		;If new data not present, ERROR
		pp_clrdrwp			;Clear DRW flag

		pp_readport			;Read port
		cmp	#def_linkchk_byte1	;$5A?
		bne	$$noparallel
		pp_chkdrwp			;Check DRW flag
		beq	$$noparallel		;If new data not present, ERROR
		pp_clrdrwp			;Clear DRW flag

		pp_readport			;Read port
		cmp	#def_linkchk_byte2	;$A5?
		bne	$$noparallel
		ser_setdat 1			;Release DAT
		jsr	rom_primm
		BYT	" LINK OK!",0
		cli
		clc
		rts

$$noparallel	ser_setdat 1			;Release DAT
		jsr	rom_primm
		BYT	" LINK ERROR!",0
		cli
		sec				;No correct parallel link
		rts
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode
	BINCLUDE "recvtimepp-drive.bin"
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
