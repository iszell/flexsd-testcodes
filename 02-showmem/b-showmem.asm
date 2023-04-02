;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.06.+ by BSZ
;---	Show VCPU memory
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	"SHOW SD2IEC VCPU MEM:",ascii_return,0

		jsr	sd2i_scanning_bus
		sta	z_fa				;Set SD2IEC Unit No
		cmp	#0				;Any SD2IEC on the bus?
		bne	$$sd2iecpresent
		jsr	rom_primm
		BYT	ascii_return,"NO SD2IEC DETECTED",0
		jmp	$$exit
$$sd2iecpresent	jsr	rom_primm
		BYT	ascii_return,"SD2IEC UNIT NO: #",0
		ldx	z_fa
		lda	#0
		jsr	bas_linprt

		jsr	sd2i_checkvcpusupport		;Check SD2IEC VCPU support
		bcc	$$vcpuready
		jmp	$$exit
$$vcpuready	sta	$$rampagemax
		jsr	rom_primm
		BYT	ascii_return,"VCPU MEMORY SIZE:",0
		ldx	#0
		jsr	bas_linprt
		lda	#ascii_return
		jsr	rom_bsout

		lda	#0
		sta	_rampage
		sta	_displaypos

$$bigcyc	lda	_rampage
		jsr	readblock
$$smallcyc	jsr	print_datablock
		jsr	rom_primm
		BYT	ascii_return
		BYT	ascii_return,"CRSR UP/DOWN: MOVE"
		BYT	ascii_return,"SPACE: EXIT",0
$$waitkey	jsr	wait_keypress
		cmp	#ascii_up
		beq	$$key_up
		cmp	#ascii_down
		beq	$$key_down
		cmp	#' '
		bne	$$waitkey
		jsr	rom_primm
		BYT	ascii_return,"  -EXIT...-",0
$$exit		rts

$$key_up	lda	_displaypos
		beq	$$key_up_cb
		sec
		sbc	#8*8
		sta	_displaypos
		jmp	$$go_smallcyc
$$key_up_cb	ldx	_rampage
		beq	$$waitkey
		dex
		stx	_rampage
		lda	#256-(8*8)
		sta	_displaypos
		jmp	$$go_bigcyc

$$key_down	lda	_displaypos
		cmp	#256-(8*8)
		beq	$$key_down_cb
		clc
		adc	#8*8
		sta	_displaypos
$$go_smallcyc	jsr	$$cursormove
		jmp	$$smallcyc
$$key_down_cb	ldx	_rampage
		inx
		cpx	$$rampagemax
		beq	$$waitkey
		stx	_rampage
		lda	#0
		sta	_displaypos
$$go_bigcyc	jsr	$$cursormove
		jmp	$$bigcyc

$$cursormove	jsr	rom_primm
    IF target_platform = 20
		BYT	ascii_up,ascii_up,ascii_up,ascii_up
		BYT	ascii_up,ascii_up,ascii_up,ascii_up
    ENDIF
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,ascii_up
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,ascii_up
		BYT	ascii_up,0
		rts

$$rampagemax	BYT	0
;------------------------------------------------------------------------------
;---	Read 256 BYTE from drive:
;---	A <- Block no

readblock	jsr	rom_primm
		BYT	ascii_return,"READ SD2IEC VCPU MEM",ascii_up,0
		sta	$$drvmemaddr+1			;Set address Hi
		jsr	sd2i_readmemory			;Read SD2IEC VCPU memory block
$$drvmemaddr	ADR	$0000
		ADR	$0100
		ADR	_readedmemory
		rts
;------------------------------------------------------------------------------
;---	Print 64 BYTEs from block:

print_datablock	jsr	rom_primm
		BYT	ascii_return,"SD2IEC VCPU MEM:    ",ascii_return,0

		ldx	_displaypos
		ldy	_rampage
		jsr	printmem_setdispaddr
		lda	#lo(_readedmemory)
		clc
		adc	_displaypos
		tax
		lda	#hi(_readedmemory)
		adc	#0
		tay
		lda	#64
		jmp	printmem
;------------------------------------------------------------------------------
_displaypos	BYT	0
_rampage	BYT	0
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE	"../common/memory_read.asm"
	INCLUDE	"../common/waitkey.asm"
	INCLUDE	"../common/printmem.asm"
;------------------------------------------------------------------------------
_readedmemory	RMB	256
;------------------------------------------------------------------------------
