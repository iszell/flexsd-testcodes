;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2024.07.14.+ by BSZ
;---	Send/Receive test, Parallel port, computer side
;---	PPDRD/PPDWR/PPACK/PPWAI commands on drive side
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
	INCLUDE	"../common/hosthwmacros.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"srpp-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"SD2IEC SEND+RECV PARALLEL PORT:"
		BYT	ascii_return,"PPDRD/PPDWR/PPACK/PPWAI COMMANDS",ascii_return,0

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
		BYT	ascii_return,"# ",ascii_rvson,"[SPACE]",ascii_rvsoff,": EXIT"
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,0
		jsr	fillscreenfordata

		lda	#0
		sta	z_ndx			;Clear Interrupt's keyboard buffer

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

$$nokeypressed	lda	#$13			;"S"
		sta	screen_addr+$103
		sei
		ser_starttransfer		;Transfer start
		lda	#%01100110		;CONTINUE
		pp_writeport			;Send data
		inc	$$datastart
		lda	$$datastart
		sta	$$data
		ldy	#$00
$$sendcyc	pp_waitdrwp			;Wait drive's RW pulse
		lda	$$data
		pp_writeport			;Send data
		inc	$$data
		iny
		bne	$$sendcyc
		pp_waitdrwp			;Wait drive's last RW pulse
		pp_porttoin			;Switch parport to input
		cli
		lda	#$20			;" "
		sta	screen_addr+$103

		lda	#$12			;"R"
		sta	screen_addr+$103
		sei
		ser_starttransfer		;Transfer start
		ldy	#0
$$recvcyc	pp_waitdrwp			;Wait drive's RW pulse
		pp_readport			;Read data
		sta	screen_addr,y
		iny
		bne	$$recvcyc
		cli
		lda	#$20			;" "
		sta	screen_addr+$103

		lda	$$datastart
		ldy	#0
		jsr	datachecker		;Check received BYTEs
		bcs	$$errorend
		jmp	$$commtestcycle
$$errorend	jmp	$$exittestcyc

$$statexit	pp_hwdeinit
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
_drivecode	BINCLUDE "srpp-drive.bin"
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
