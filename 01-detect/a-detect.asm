;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.06.+ by BSZ
;---	Drive detect and informations
;---	240914+: Add device configurator utility
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
def_device_configer	set	"Y"		;If "Y", build detector with device configurator utility
def_setstrmaxlen	=	64		;Maximum settings string length

    IF target_platform == 20
      IF vic20_setmem == 0
def_device_configer	set	"N"		;If target is VIC20 and no memory expansion: utility disabled (out of memory)
      ENDIF
    ENDIF
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	"SD2IEC VCPU DETECTOR:",ascii_return,0

		jsr	sd2i_scanning_bus
		sta	z_fa				;Set SD2IEC Unit No
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"UNITS ON SERIAL BUS:",0
		lda	#0				;X = units on serial bus
		jsr	bas_linprt

		jsr	_printsd2iecuno			;Print SD2IEC unit no, if found
		bcc	$$devfound
		jmp	$$exit

$$devfound	jsr	sd2i_printlongversion
		jsr	rom_primm
		BYT	ascii_return,0

    IF target_platform == 20
		jsr	_pressspace
    ENDIF

		jsr	sd2i_checkvcpusupport		;Check SD2IEC VCPU support
		bcc	$$vcpuready
		jmp	$$maybeconfig
$$vcpuready	jsr	rom_primm
		BYT	ascii_return,"VCPU MEMORY SIZE:",0
		ldx	#0
		jsr	bas_linprt

		jsr	_pressspace

		jsr	rom_primm
		BYT	ascii_return,"BUFFER STATUS: ",0
		jsr	sd2i_getbuffers

    IF target_platform == 20
		jsr	_pressspace
    ENDIF

		jsr	rom_primm
		BYT	ascii_return,ascii_return,"VCPU STATUS:",0
		jsr	sd2i_getvcpustatus

$$maybeconfig
    IF def_device_configer == "Y"
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"# ",ascii_rvson,"[C]",ascii_rvsoff,": "
      IF target_platform == 20
		BYT	"CONFIG. DEVICE"
      ELSE
		BYT	"CONFIGURE DEVICE"
      ENDIF
		BYT	ascii_return,"# ",ascii_rvson,"[SPACE]",ascii_rvsoff,": EXIT",0
		jsr	wait_keypress
		cmp	#"C"			;Configure device?
		bne	$$notconfigure
		jsr	device_configurator
$$notconfigure
    ENDIF
$$exit		jmp	program_exit

;	Wait for SPACE (or any) button:
_pressspace	jsr	rom_primm
		BYT	ascii_return,"# PRESS ",ascii_rvson,"[SPACE]",ascii_rvsoff,ascii_up,0
		jsr	wait_keypress
		jsr	rom_primm
		BYT	ascii_return,"               ",ascii_up,0
		rts

;	Print SD2IEC unit no, if present
;	Cy. -> 0: Found, 1: not found
_printsd2iecuno	lda	z_fa				;Any SD2IEC on the bus?
		bne	$$sd2iecpresent
		jsr	rom_primm
		BYT	ascii_return,"NO SD2IEC DETECTED",0
		sec					;Not found
		rts
$$sd2iecpresent	jsr	rom_primm
		BYT	ascii_return,"SD2IEC UNIT NO: #",0
;	Print unit no only:
_printsd2iunoly	lda	#0
		ldx	z_fa				;Any SD2IEC on the bus?
		jsr	bas_linprt
		clc					;Found
		rts
;------------------------------------------------------------------------------
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/getlongversion.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE	"../common/getbuffers.asm"
	INCLUDE	"../common/getvcpustatus.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/waitkey.asm"
    IF def_device_configer == "Y"
	INCLUDE "configutil.asm"		;Device configuration utility, if needed
    ENDIF
;------------------------------------------------------------------------------
