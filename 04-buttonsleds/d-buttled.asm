;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.12.+ by BSZ
;---	Buttons + LEDs, computer side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"buttled-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"SD2IEC BUTTONS+LEDS:",ascii_return,0

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
$$vcpuready	jsr	rom_primm
		BYT	ascii_return,"DOWNLOAD CODE TO DRV",0
		jsr	sd2i_writememory
		ADR	$$drivecode
		ADR	$$drivecode_end-$$drivecode
		ADR	drivecode_start

		jsr	rom_primm
		BYT	ascii_return,"START CODE IN DRV",0
		ldx	#lo(drivecode_start)
		ldy	#hi(drivecode_start)
		jsr	sd2i_execmemory_simple

		jsr	rom_primm
		BYT	ascii_return,ascii_return,"PREV/NEXT TO LEDS"
		BYT	ascii_return,"C/V: CLK ASSERT/REL"
		BYT	ascii_return,"D/F: DAT ASSERT/REL"
		BYT	ascii_return,ascii_return,"  -SPACE TO EXIT-",0
$$waitcycle	jsr	wait_keypress
		cmp	#'C'
		bne	$$notc
		jsr	rom_ser_clklo
		jmp	$$waitcycle
$$notc		cmp	#'V'
		bne	$$notv
		jsr	rom_ser_clkhi
		jmp	$$waitcycle
$$notv		cmp	#'D'
		bne	$$notd
		jsr	rom_ser_datlo
		jmp	$$waitcycle
$$notd		cmp	#'F'
		bne	$$notf
		jsr	rom_ser_dathi
		jmp	$$waitcycle
$$notf		cmp	#' '
		bne	$$waitcycle
		jsr	rom_ser_clkhi
		jsr	rom_ser_dathi
		jsr	rom_primm
		BYT	ascii_up,ascii_return,"EXIT, GET DRV STATUS:",ascii_return,0
		jsr	sd2i_printstatus
		jsr	rom_primm
		BYT	ascii_return,"('97,VCPU ERROR,100,04' IS OK.)",ascii_return,0
		jsr	rom_primm
		BYT	ascii_return,"VCPU STATUS:",0
		jsr	sd2i_getvcpustatus
		jsr	rom_primm
		BYT	ascii_return,0
$$exit		rts

;	Previously compiled drivecode binary:
$$drivecode	BINCLUDE "buttled-drive.prg"
$$drivecode_end
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/getvcpustatus.asm"
	INCLUDE	"../common/waitkey.asm"
;------------------------------------------------------------------------------
