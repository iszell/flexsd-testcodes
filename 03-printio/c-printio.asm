;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.17.+ by BSZ
;---	Print I/O area - computer side
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"printio-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	"PRINT SD2IEC VCPU I/O:",ascii_return,0

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
$$vcpuready	lda	_vcpu_ioarea_size
		sta	$$drivecode+0			;Drivecode's first BYTE = I/O area size
		jsr	rom_primm
		BYT	ascii_return,"DOWNLOAD CODE TO DRV",0
		jsr	sd2i_writememory
		ADR	$$drivecode
		ADR	$$drivecode_end-$$drivecode
		ADR	drivecode_start

		jsr	rom_primm
		BYT	ascii_return,"START CODE IN DRV",0
		ldx	#lo(drivecode_go)
		ldy	#hi(drivecode_go)
		jsr	sd2i_execmemory_simple

		jsr	rom_primm
		BYT	ascii_return,"WAIT A MOMENT...",0
		ldx	#5
		jsr	wait_frames

		jsr	rom_primm
		BYT	ascii_return,"READ STATUS: ",0
		jsr	sd2i_printstatus
		cmp	#$00					;"00, OK,00,00"?
		beq	$$statusok
		jsr	rom_primm
		BYT	ascii_return,"ERROR!",ascii_return,0
		jmp	$$exit

$$statusok	jsr	rom_primm
		BYT	ascii_return,ascii_return,"READ BACK RESULTS",0
		lda	_vcpu_ioarea_size
		sta	$$rddatend+0
		jsr	sd2i_readmemory
		ADR	readeddatas
$$rddatend	ADR	$0000
		ADR	_result

		jsr	rom_primm
		BYT	ascii_return,ascii_return,"SD2IEC VCPU I/O:",ascii_return,0

		ldx	#lo(vcpu_iobase)
		ldy	#hi(vcpu_iobase)
		jsr	printmem_setdispaddr
		ldx	#lo(_result)
		ldy	#hi(_result)
		lda	_vcpu_ioarea_size
		jsr	printmem

$$exit		jmp	program_exit

;	Previously compiled drivecode binary:
$$drivecode	BYT	0			;<- I/O area size
		BINCLUDE "printio-drive.bin", 1
$$drivecode_end
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE	"../common/printstatus.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE "../common/memory_read.asm"
	INCLUDE	"../common/waitkey.asm"
	INCLUDE	"../common/waittime.asm"
	INCLUDE	"../common/printmem.asm"
;------------------------------------------------------------------------------
_result
;------------------------------------------------------------------------------
