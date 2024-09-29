;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.10.16.+ by BSZ
;---	Send/Receive test, C128, Fast Serial, computer side
;---	UFSTX/UFSRX commands on drive side
;---	  Comment: Data send/receive works on a timing instead of checking
;---		   the SP flag of the CIA. This flag is cleared by the
;---		   original C128 interrupt routine, and this conflicts with
;---		   the current test codes.
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"srfs-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"SD2IEC SEND+RECV FAST SERIAL:"
		BYT	ascii_return,"FSTXB/FSRXB COMMANDS",ascii_return,0

    IF target_platform <> 128
	INCLUDE "../common/c128onlytxt.asm"
    ELSE
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
		cmp	#3<<5				;FASTSER?
		beq	$$vcpufastser
		cmp	#5<<5				;FASTSER+PAR?
		beq	$$vcpufastser
		jsr	rom_primm
		BYT	ascii_return,"DRIVE NOT SUPPORT FAST SERIAL",0
		jmp	$$exit
$$vcpufastser	jsr	rom_primm
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

		jsr	checkfslink
		bcc	$$fslinkok
		jmp	$$exit

$$fslinkok	jsr	rom_primm
		BYT	ascii_return,"# ",ascii_rvson,"[SPACE]",ascii_rvsoff,": EXIT"
		BYT	ascii_return,ascii_return,ascii_return,ascii_return
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,0
		jsr	fillscreenfordata

		lda	#0
		sta	z_ndx		;Clear Interrupt's keyboard buffer

$$commtestcycle	lda	$dd00			;CIA port for handle serial lines
		and	#%11000000
		cmp	#%11000000		;DAT+CLK = high?
		bne	$$commtestcycle

		lda	z_ndx			;Any key pressed?
		beq	$$nokeypressed
$$exittestcyc	jsr	setfstotransmit		;Set Fast Serial to data transmit
		lda	#$00			;EXIT
		jsr	fsbytesender
		jsr	setfstoreceive		;Set Fast Serial to data receive
		jsr	rom_primm
		BYT	ascii_return,"COMM TEST END.",0
		jmp	$$statexit

$$nokeypressed	jsr	setfstotransmit		;Set Fast Serial to data transmit
		lda	#%01100110
		jsr	fsbytesender		;CONTINUE

		inc	$$datastart
		lda	$$datastart
		sta	$$data
		ldy	#$00
$$sendcyc	lda	$$data
		jsr	fsbytesender
		inc	$$data
		iny
		bne	$$sendcyc

		jsr	setfstoreceive		;Set Fast Serial to data receive

		lda	$dd00
		tax				;CLK high
		ora	#%00010000		;Set CLK to Low
		sta	$dd00
		ldy	#0
		jsr	fsbytewait		;Wait first BYTE

$$recvcyc	jsr	fsbytereceiver		;33
		sta	screen_addr,y		;5
		nop				;2
		bit	$00			;3
		iny				;2
		bne	$$recvcyc		;3(2)	48 clk cycle

		lda	$dd00
		and	#%11000111		;Release CLK, DAT (ATN)
		sta	$dd00
		lda	$$datastart
		ldy	#0
		jsr	datachecker		;Check received BYTEs
		bcs	$$exittestcyc
		jmp	$$commtestcycle

$$statexit	jsr	rom_primm
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
;---	Check Fast Serial link:
checkfslink	sei
		jsr	rom_primm
		BYT	ascii_return,"CHECK FASTSER LINK:",0

		clc
		jsr	rom_spin_spout		;Set to input (receive)
		bit	$dc0d			;Clear SDR flag

$$waitclkl	bit	$dd00
		bvs	$$waitclkl		;Wait for CLK low

		lda	$dd00
		ora	#%00100000
		sta	$dd00			;DAT to Low
		and	#%11011111
		sta	$dd00			;DAT to HiZ
$$waitclkh	bit	$dd00
		bvc	$$waitclkh		;Wait for CLK Hi

		lda	$dc0d			;ICR
		and	#%00001000		;SDR flag?
		beq	$$nofastserdat
		lda	#'R'
		jsr	rom_bsout
		lda	$dc0c			;SDR
		cmp	#def_linkchk_byte	;Transmitted BYTE?
		bne	$$bugfastserdat
		jsr	mon_puthex
		jsr	rom_primm
		BYT	" LINK OK!",0
		cli
		clc
		rts

$$nofastserdat	lda	#'X'
		jsr	rom_bsout
		lda	$dc0c			;SDR
$$bugfastserdat	jsr	mon_puthex
		jsr	rom_primm
		BYT	" LINK ERROR!",0
		cli
		sec				;No Fast Serial data received
		rts
;------------------------------------------------------------------------------
;---	Turn fast serial to data transmit:
setfstotransmit	lda	$d505			;MMU MCR
		ora	#%00001000		;FSDIR to output
		sta	$d505
		lda	#%01111111
		sta	$dc0d			;Disable IRQs
		lda	$dc0e
		and	#%10000000		;Keep TOD speed
		ora	#%01010101		;Set ShiftReg to output, select clock, ...
		sta	$dc0e
		bit	$dc0d			;Clear pending IRQ bits
		rts
;------------------------------------------------------------------------------
;---	Send BYTE to fast serial, wait only for timing:
;---	One BYTE send in 64 CPU cycle:
;---	A <- BYTE to be send

fsbytesender	sta	$dc0c			;4	Data set to SDR

;---	Wait 64+6+6 clk. cycle (one BYTE transmit + jitter)
fsbytewait	jsr	$$wait			;12
		jsr	$$wait			;12
		jsr	$$wait			;12
		jsr	$$wait			;12
		jsr	$$wait			;12
		bit	$dc0d			;4	Clear SDR flag
$$wait		rts				;6	76 with JSR
;------------------------------------------------------------------------------
;---	Turn fast serial _back_ to data receive:
setfstoreceive	jsr	fsbytewait		;76	...wait a bit...
		lda	$dc0e
		and	#%10000000		;Keep TOD speed
		ora	#%00001000		;Set ShiftReg to input
		sta	$dc0e
		lda	$d505			;MMU MCR
		and	#%11110111		;FSDIR to input
		sta	$d505
$$wait		rts
;------------------------------------------------------------------------------
;---	Get BYTE from fast serial:
;---	A -> received BYTE
fsbytereceiver	lda	$dc0c			;4	Get data from SDR
		stx	$dd00			;4	Set Clock
		pha				;3
		txa				;2
		eor	#%00010000		;2	Toggle CLK
		tax				;2
		pla				;4
		rts				;6	33 with JSR
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode	BINCLUDE "srfs-drive.bin"
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
    ENDIF
;------------------------------------------------------------------------------
