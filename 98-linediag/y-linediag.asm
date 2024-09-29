;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.04.+ by BSZ
;---	Line diagnostics - computer side
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"linediag-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,"LINE DIAGNOSTICS:",ascii_return,0

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
		ldx	#lo(_measvalues)
		ldy	#hi(_measvalues)	;Results stored here
		lda	#100			;error buffer size = 100, max no of BYTEs
		jsr	sd2i_recvanswer
		sty	_recvlength		;Save received data length
		cpy	#48			;48 BYTEs received? (For FAST SERIAL: incl. SRQ line data)
		beq	$$lengthok
		cpy	#36			;36 BYTEs received?
		bne	$$maybeerror
$$lengthok	lda	_measvalues+0
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
		BYT	ascii_return,ascii_return,"MAYBE ERROR? RCV.STR:",ascii_return,0
		ldx	#0
$$errorprint	lda	_measvalues,x
		cmp	#ascii_return
		beq	$$printvalues
		jsr	rom_bsout
		inx
		cpx	_recvlength
		bne	$$errorprint

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
		lda	_recvlength
		cmp	#48			;SRQ data present?
		bne	$$nosrq
		jsr	rom_primm
		BYT	ascii_return,"SRQ:",0
		jsr	print12byte

$$nosrq		jsr	rom_primm
		BYT	ascii_return,0
$$exit		jmp	program_exit

;	Previously compiled drivecode binary:
$$drivecode	BINCLUDE "linediag-drive.bin"
$$drivecode_end

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

_recvlength	BYT	0
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
