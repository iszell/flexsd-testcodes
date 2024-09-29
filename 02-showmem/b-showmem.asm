;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.06.+ by BSZ
;---	Show VCPU memory
;---	240603+: Add kernal communication test
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
    IFNDEF vic20_setmem
vic20_setmem	set	0
    ENDIF

def_kerncommtst	=	"Y"			;If "Y": kernal comm test included
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
;------------------------------------------------------------------------------
		jsr	rom_primm
    IF (target_platform == 264) || (target_platform == 128)
		BYT	ascii_esc,"N",ascii_esc,"C"	;ESC+N: screen size: 40×25 char, ESC+C: disable insert mode
    ENDIF
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
$$vcpuready	sta	_rampagemax

		lda	#0
		sta	_rampage
		sta	_displaypos

$$vcpustatus	jsr	rom_primm
		BYT	ascii_return,ascii_return,"VCPU STATUS:",0
		jsr	sd2i_getvcpustatus
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"VCPU MEMORY SIZE:",0
		lda	_rampagemax
		ldx	#0
		jsr	bas_linprt
		lda	#ascii_return
		jsr	rom_bsout

    IF target_platform == 20
		jsr	rom_primm
		BYT	"# PRESS ",ascii_rvson,"[SPACE]",ascii_rvsoff,ascii_up,ascii_return,0
		jsr	wait_keypress
		jsr	rom_primm
		BYT	"               ",ascii_return,0
    ENDIF

$$bigcyc	lda	_rampage
		jsr	readblock
$$smallcyc	jsr	print_datablock
		jsr	rom_primm
		BYT	ascii_return
		BYT	ascii_return,"# ",ascii_rvson,"[UP]",ascii_rvsoff,"/"
		BYT	ascii_rvson,"[DOWN]",ascii_rvsoff,": MOVE"
    IF target_platform == 20
		BYT	ascii_return,"# ",ascii_rvson,"[S]",ascii_rvsoff,": VCPU STATUS"
    ENDIF
    IF (((target_platform == 20) && (vic20_setmem == 8)) || (target_platform <> 20))
		BYT	ascii_return,"# ",ascii_rvson,"[R]",ascii_rvsoff,": READ VCPU MEM"
    ENDIF
    IF def_kerncommtst == "Y"
      IF target_platform == 20
		BYT	ascii_return,"# ",ascii_rvson,"[T]",ascii_rvsoff,": KERNL COMM TST"
      ELSE
		BYT	ascii_return,"# ",ascii_rvson,"[T]",ascii_rvsoff,": KERNAL COMM TEST"
      ENDIF
    ENDIF
		BYT	ascii_return,"# ",ascii_rvson,"[SPACE]",ascii_rvsoff,": EXIT",0
$$waitkey	jsr	wait_keypress
		cmp	#ascii_up
		beq	$$key_up
		cmp	#ascii_down
		beq	$$key_down
    IF target_platform == 20
		cmp	#'S'
		beq	$$key_s
    ENDIF
    IF (((target_platform == 20) && (vic20_setmem == 8)) || (target_platform <> 20))
		cmp	#'R'
		beq	$$key_r
    ENDIF
    IF def_kerncommtst == "Y"
		cmp	#'T'
		beq	$$key_t
    ENDIF
		cmp	#' '
		bne	$$waitkey
$$exit		jmp	program_exit

    IF target_platform == 20
$$key_s		jmp	$$vcpustatus
    ENDIF
    IF (((target_platform == 20) && (vic20_setmem == 8)) || (target_platform <> 20))
$$key_r		jsr	readdrvmemtoram
		jmp	$$exit
    ENDIF
    IF def_kerncommtst == "Y"
$$key_t		jmp	kernalcommtest
    ENDIF

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
		cpx	_rampagemax
		beq	$$waitkey
		stx	_rampage
		lda	#0
		sta	_displaypos
$$go_bigcyc	jsr	$$cursormove
		jmp	$$bigcyc

$$cursormove	jsr	rom_primm
    IF target_platform == 20
		BYT	ascii_up,ascii_up,ascii_up,ascii_up
		BYT	ascii_up,ascii_up,ascii_up,ascii_up	;+8 line: VIC20: only 4 bytes / line
		BYT	ascii_up				;+1 line: VIC20: "S: VCPU STATUS"
    ENDIF
    IF (((target_platform == 20) && (vic20_setmem == 8)) || (target_platform <> 20))
		BYT	ascii_up				;+1 line: "R: READ VCPU MEM"
    ENDIF
    IF def_kerncommtst == "Y"
		BYT	ascii_up				;+1 line: "T: KERNAL COMM TEST"
    ENDIF
    IF target_platform <> 20
		BYT	ascii_up
    ENDIF
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,ascii_up
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up
		BYT	ascii_return,ascii_up
		BYT	0
		rts
;------------------------------------------------------------------------------
;---	Read VCPU memory to host RAM:
    IF (((target_platform == 20) && (vic20_setmem == 8)) || (target_platform <> 20))
readdrvmemtoram	ldx	_vcpustatus_siz			;Copy VCPU status
		dex
$$statcopy	lda	_vcpustatus,x
		sta	dump_vcpustatus,x
		dex
		bpl	$$statcopy

		lda	#hi($0000)
		sta	$$drvmemaddr+1			;VCPU memory start address set to $0000
		lda	#hi(dump_vcpuram)
		sta	$$hostmemaddr+1			;Host memory start address set

		jsr	rom_primm
		BYT	ascii_return,"READ DRIVE MEM: ",0
		lda	$$drvmemaddr+1
		ldx	$$drvmemaddr+0
		jsr	$$printhexword

$$readmemcyc	lda	#'.'
		jsr	rom_bsout
		lda	$$drvmemaddr+1
		ldx	#$ff
		jsr	$$printhexword
		jsr	rom_primm
		BYT	ascii_left,ascii_left,ascii_left,ascii_left,0
		jsr	sd2i_readmemory			;Read SD2IEC VCPU memory block
$$drvmemaddr	ADR	$0000
		ADR	$0100
$$hostmemaddr	ADR	dump_vcpuram
		inc	$$drvmemaddr+1
		inc	$$hostmemaddr+1			;Next block
		lda	$$drvmemaddr+1
		cmp	_rampagemax			;Full memory is readed?
		bne	$$readmemcyc
		jsr	rom_primm
		BYT	ascii_return,"DRIVE STATUS: ",0
		lda	#hi(dump_vcpustatus)
		ldx	#lo(dump_vcpustatus)
		jsr	$$printhexword
		jsr	rom_primm
		BYT	"...",ascii_return,"DRIVE MEM: ",0
		lda	#hi(dump_vcpuram)
		ldx	#lo(dump_vcpuram)
		jsr	$$printhexword
		jsr	rom_primm
		BYT	"..",0
		lda	$$hostmemaddr+1
		ldx	$$hostmemaddr+0
		;jmp	$$printhexword

$$printhexword	jsr	mon_puthex
		txa
		jmp	mon_puthex
    ENDIF
;------------------------------------------------------------------------------
;---	Read 256 BYTE from drive:
;---	A <- Block no

readblock	jsr	rom_primm
		BYT	ascii_return,ascii_up,"READ SD2IEC VCPU MEM",0
		sta	$$drvmemaddr+1			;Set address Hi
		jsr	sd2i_readmemory			;Read SD2IEC VCPU memory block
$$drvmemaddr	ADR	$0000
		ADR	$0100
		ADR	_readedmemory
		jsr	rom_primm
		BYT	ascii_return,ascii_up,0
		rts
;------------------------------------------------------------------------------
;---	Print 64 BYTEs from block:

print_datablock	jsr	rom_primm
		BYT	ascii_return,ascii_up,"SD2IEC VCPU MEM:    "
    IF target_platform <> 20
		BYT	ascii_return
    ENDIF
		BYT	0

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
;---	KERNAL communication test:
;---	Fill devices memory of pseudo-random data then read back and check:

    IF def_kerncommtst == "Y"
kernalcommtest	jsr	rom_primm
		BYT	ascii_return,ascii_return,"KERNAL COMM TEST",0

		jsr	sd2i_getbuffers		;Get buffer status
		ldx	#0
$$checkempty	lda	_bufferstates+0,x
		and	#%00000001		;Used/Free bit remain
		beq	$$bufferfree
		jsr	rom_primm
		BYT	ascii_return,"NOT FREE ALL BUFFERS"
		BYT	ascii_return,"RESET DRIVE AND RERUN THIS TEST",0
		jmp	program_exit
$$bufferfree	inx
		inx
		cpx	_buffst_byteno
		bne	$$checkempty

		jsr	rom_primm
		BYT	ascii_return,"# ",ascii_rvson,"[SPACE]",ascii_rvsoff,": EXIT",0

		lda	#0
		sta	_passno+0
		sta	_passno+1	;First pass
		sta	_errors+0
		sta	_errors+1
		sta	_errors+2
		sta	_errors+3	;No errors
		sta	z_ndx		;Clear Interrupt's keyboard buffer

$$newpass	inc	_passno+0
		bne	$$ncy
		inc	_passno+1
$$ncy		jsr	rom_primm
		BYT	ascii_return,ascii_return,"KERN.C.T, ROUND:",0
		ldx	_passno+0
		lda	_passno+1
		jsr	bas_linprt

		jsr	rnd_setnextseed
		lda	#0
		sta	_bufferno		;Start with buffer #0
		jsr	rom_primm
		BYT	ascii_return,"WRTE:",0
		jsr	$$lineclear

$$sendcycle	lda	#'W'
		jsr	rom_bsout		;Print "W"
;	Create one buffer random data
		ldx	#0
$$generaternd	jsr	rnd_getdata
		sta	_readedmemory,x
		inx
		bne	$$generaternd
;	Send data to VCPU memory
		lda	_bufferno
		sta	$$vcpuwraddr+1		;Set VCPU address Hi
		jsr	sd2i_writememory
		ADR	_readedmemory
		ADR	$0100
$$vcpuwraddr	ADR	$0000
;	Next buffer...
		inc	_bufferno
		lda	_bufferno
		cmp	_vcpu_memory_size	;All buffers filled?
		bne	$$sendcycle

;	Read back and check:
		jsr	rnd_setseed		;Re-set random seed
		lda	#0
		sta	_bufferno		;Start with buffer #0
		jsr	rom_primm
		BYT	ascii_return,"READ:",0
		jsr	$$lineclear

$$recvcycle	lda	#'R'
		jsr	rom_bsout		;Print "R"
;	Read back VCPU memory block:
		lda	_bufferno
		sta	$$vcpurdaddr+1
		jsr	sd2i_readmemory
$$vcpurdaddr	ADR	$0000
		ADR	$0100
		ADR	_readedmemory
;	Check readed data:
		ldx	#0
$$checkrnd	jsr	rnd_getdata
		cmp	_readedmemory,x
		beq	$$checkokay
		jsr	rom_primm
		BYT	ascii_left,"E",0
		inc	_errors+0
		bne	$$checkokay
		inc	_errors+1
$$checkokay	inx
		bne	$$checkrnd
;	Next buffer...
		inc	_bufferno
		lda	_bufferno
		cmp	_vcpu_memory_size	;All buffers checked?
		bne	$$recvcycle

;	Pass ready, start next:
		jsr	rom_primm
		BYT	ascii_return,"RDY, ERROR NO:",0
		ldx	_errors+0
		lda	_errors+1
		jsr	bas_linprt
		lda	_errors+0
		eor	_errors+2
		bne	$$modified
		lda	_errors+1
		eor	_errors+3
		beq	$$nomodified
$$modified	lda	_errors+0
		sta	_errors+2
		lda	_errors+1
		sta	_errors+3
		jmp	$$nextcycle
$$nomodified	jsr	rom_primm
		BYT	ascii_up,ascii_up,ascii_up,ascii_up,ascii_up,0

$$nextcycle	lda	z_ndx
		bne	$$keypress
		jmp	$$newpass
$$keypress	;lda	_keyd+0		;Get ASCII code of pressed key
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,ascii_return,ascii_return,0
		lda	#0
		sta	z_ndx		;Clear Interrupt's keyboard buffer
		jmp	program_exit

$$lineclear	jsr	rom_primm
		BYT	"                "
		BYT	ascii_left,ascii_left,ascii_left,ascii_left
		BYT	ascii_left,ascii_left,ascii_left,ascii_left
		BYT	ascii_left,ascii_left,ascii_left,ascii_left
		BYT	ascii_left,ascii_left,ascii_left,ascii_left,0
		rts



;	pseudo-random codes:
rnd_setnextseed	inc	_seed
		bne	rnd_setseed
		inc	_seed

rnd_setseed	lda	_seed
		sta	_rnd
		rts

rnd_getdata	lsr	_rnd
		lda	_rnd
		bcc	$$ready
		eor	#%10111000
		sta	_rnd
$$ready		eor	_passno+0
		eor	_bufferno
		rts

_passno		ADR	0
_errors		ADR	0,0
_bufferno	BYT	0
_seed		BYT	1
_rnd		BYT	0

    ENDIF
;------------------------------------------------------------------------------
_displaypos	BYT	0
_rampage	BYT	0
_rampagemax	BYT	0
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE	"../common/getvcpustatus.asm"
	INCLUDE	"../common/memory_read.asm"
	INCLUDE	"../common/waitkey.asm"
	INCLUDE	"../common/printmem.asm"
	INCLUDE	"../common/waittime.asm"
    IF def_kerncommtst == "Y"
	INCLUDE	"../common/getbuffers.asm"
	INCLUDE	"../common/memory_write.asm"
    ENDIF
;------------------------------------------------------------------------------
_readedmemory	RMB	256
;------------------------------------------------------------------------------
;---	VCPU status and memory dump area:
    IF (((target_platform == 20) && (vic20_setmem == 8)) || (target_platform <> 20))
	ALIGN	256
dump_vcpustatus	RMB	20
	ALIGN	256
dump_vcpuram	RMB	15*256
    ENDIF
;------------------------------------------------------------------------------
