;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.06.+ by BSZ
;---	Drive detect and informations
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	"SD2IEC VCPU DETECTOR:",ascii_return,0

		jsr	sd2i_scanning_bus
		sta	z_fa				;Set SD2IEC Unit No
		stx	$$unitsonserial
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"UNITS ON SERIAL BUS:",0
		ldx	$$unitsonserial
		lda	#0
		jsr	bas_linprt

		ldx	z_fa
		lda	#0
		cpx	#0				;Any SD2IEC on the bus?
		bne	$$sd2iecpresent
		jsr	rom_primm
		BYT	ascii_return,"NO SD2IEC DETECTED",0
		jmp	$$exit
$$sd2iecpresent	jsr	rom_primm
		BYT	ascii_return,"SD2IEC UNIT NO: #",0
		jsr	bas_linprt

		jsr	sd2i_printlongversion

		jsr	sd2i_checkvcpusupport		;Check SD2IEC VCPU support
		bcc	$$vcpuready
		jmp	$$exit
$$vcpuready	jsr	rom_primm
		BYT	ascii_return,"VCPU MEMORY SIZE:",0
		ldx	#0
		jsr	bas_linprt

		jsr	rom_primm
		BYT	ascii_return,         "  -PRESS SPACE-",0
		jsr	wait_keypress

		jsr	rom_primm
		BYT	ascii_up,ascii_return,"BUFFER STATUS: ",0
		jsr	sd2i_getbuffers

		jsr	rom_primm
		BYT	ascii_return,ascii_return,"VCPU STATUS:",0
		jsr	sd2i_getvcpustatus

		jsr	rom_primm
		BYT	ascii_return,0

$$exit		rts

$$unitsonserial	BYT	0
;------------------------------------------------------------------------------
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/getlongversion.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE	"../common/getbuffers.asm"
	INCLUDE	"../common/getvcpustatus.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE	"../common/waitkey.asm"
;------------------------------------------------------------------------------
