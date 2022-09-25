;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.04.+ by BSZ
;---	Line diagnostics - computer side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"linediag-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"LINE DIAGNOSTICS:",ascii_return,0

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
		jsr	sd2i_printlongversion		;Print SD2IEC Long Version
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
		BYT	ascii_return,"WAIT A MOMENT...",0
		ldx	#5
		jsr	wait_frames

		jsr	rom_primm
		BYT	ascii_return,"READ BACK RESULTS",0
		jsr	read_errorchannel
		cpy	#36			;36 BYTEs received?
		bne	$$maybeerror
		lda	_measvalues+0
		and	#%11110000
		cmp	#'0'
		bne	$$printvalues
		lda	_measvalues+1
		and	#%11110000
		cmp	#'0'
		bne	$$printvalues
		lda	_measvalues+2
		cmp	#','
		bne	$$printvalues
$$maybeerror	jsr	rom_primm
		BYT	ascii_return,ascii_return,"MAYBE ERROR?",0

$$printvalues	jsr	rom_primm
		BYT	ascii_return,ascii_return,"  RESULTS:"
		BYT	ascii_return,"DAT:",0
		ldy	#0
		jsr	print12byte
		jsr	rom_primm
		BYT	ascii_return,"CLK:",0
		jsr	print12byte
		jsr	rom_primm
		BYT	ascii_return,"ATN:",0
		jsr	print12byte

		jsr	rom_primm
		BYT	ascii_return,0
$$exit		rts

;	Previously compiled drivecode binary:
$$drivecode	BINCLUDE "linediag-drive.prg"
$$drivecode_end

;	Read back results:
read_errorchannel
		lda	#%00000000
		sta	z_status
		lda	z_fa			;Unit No
		jsr	rom_talk
		lda	#$6f			;Error channel
		sta	z_sa
		jsr	rom_tksa
		ldy	#0
$$readdata	bit	z_status
		bvs	$$dataend
		jsr	rom_acptr
		sta	_measvalues,y
		iny
		bne	$$readdata
$$dataend	jmp	rom_untlk

;	Display 12 BYTE:
;	Y <- Start index
print12byte	ldx	#0
$$printcycle	txa
		and	#%00000011
		bne	$$nospace
		lda	#' '
		jsr	rom_bsout
$$nospace	lda	_measvalues,y
		jsr	mon_puthex
		iny
		inx
		cpx	#12
		bne	$$printcycle
		rts
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/getlongversion.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE "../common/memory_read.asm"
	INCLUDE	"../common/waitkey.asm"
	INCLUDE	"../common/waittime.asm"
	INCLUDE	"../common/printmem.asm"
;------------------------------------------------------------------------------
_measvalues
;------------------------------------------------------------------------------
