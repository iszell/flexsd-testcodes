;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.09.17.+ by BSZ
;---	VCPU core test
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"vcpuctst-drive.inc"
;------------------------------------------------------------------------------
;---	If target = VIC20, not enough memory in default configuration
def_memok	set	"Y"
    IF target_platform = 20
      IF vic20_setmem = 0
def_memok	set	"N"
      ELSEIF vic20_setmem = 3
def_memok	set	"Y"
      ELSEIF vic20_setmem = 8
def_memok	set	"Y"
      ENDIF
    ENDIF
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,"VCPU CORE TESTS:",ascii_return,0

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
$$vcpuready	sta	_vcpubufferno			;Save VCPU buffer no

    IF def_memok = "Y"
		jsr	coretests			;Run test
    ELSE
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"MORE MEMORY NEEDED",0
    ENDIF
		jsr	rom_primm
		BYT	ascii_return,0
$$exit		rts
;------------------------------------------------------------------------------
    IF def_memok = "Y"
	INCLUDE	"vcpuc-misc.asm"		;Misc functions
	INCLUDE	"vcpuc-comp.asm"		;VCPU core test functions, computer side
_drivecodes
	BINCLUDE "vcpuctst-drive.prg"		;VCPU core test functions, drive side
    ENDIF
;------------------------------------------------------------------------------
displaylevel	set	0
	INCLUDE	"../common/checkvcpusupport.asm"
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE "../common/memory_read.asm"
	INCLUDE	"../common/waittime.asm"
	INCLUDE	"../common/printmem.asm"
displaylevel	set	2
	INCLUDE	"../common/getvcpustatus.asm"
;------------------------------------------------------------------------------
_vcpubufferno	RMB	1
_membuffer	RMB	256
;------------------------------------------------------------------------------
