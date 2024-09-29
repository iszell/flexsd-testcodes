;------------------------------------------------------------------------------
;---	BASIC header (and others)
;------------------------------------------------------------------------------
    IF target_platform == 20
      IF vic20_setmem == 0
targetstring	=	"VIC20"
start_addr	=	$1001
      ELSEIF vic20_setmem == 3
targetstring	=	"V20+3"
start_addr	=	$0401
      ELSEIF vic20_setmem == 8
targetstring	=	"V20+8"
start_addr	=	$1201
      ELSE
	ERROR "No correct VIC20 memory size definied!"
      ENDIF
    ELSEIF target_platform == 64
targetstring	=	"C64"
start_addr	=	$0801
    ELSEIF target_platform == 264
targetstring	=	"C264"
start_addr	=	$1001
    ELSEIF target_platform == 128
targetstring	=	"C128"
start_addr	=	$1c01
    ENDIF

	ORG	start_addr - 2
		ADR	start_addr
		ADR	$$basend, 2024
		BYT	$9e
		BYT	$30 + ((start_continue # 10000) / 1000)
		BYT	$30 + ((start_continue # 1000) / 100)
		BYT	$30 + ((start_continue # 100) / 10)
		BYT	$30 + ((start_continue # 10) / 1)
		BYT	0
$$basend	BYT	0,0

    IF (target_platform == 20) || (target_platform == 64)
;	PRIMM: VIC20/C64: no KERNAL PRint IMMediate:
rom_primm	pha
		tya
		pha
		txa
		pha
		tsx
		lda	$0104,x
		sta	$$getchar+1
		lda	$0105,x
		sta	$$getchar+2
		ldy	#1
$$getchar	lda	$ffff,y
		beq	$$stringend
		jsr	rom_bsout
		iny
		bne	$$getchar

$$stringend	tya
		tsx
		clc
		adc	$$getchar+1
		sta	$0104,x
		lda	#0
		adc	$$getchar+2
		sta	$0105,x
		pla
		tax
		pla
		tay
		pla
		rts
;	PUTHEX: VIC20/C64: No MONITOR's PUTHEX
mon_puthex	stx	$$xrestore+1
		jsr	$$toascii
		jsr	rom_bsout
		txa
$$xrestore	ldx	#$00
		jmp	rom_bsout
$$toascii	pha
		jsr	$$ltoasc
		tax
		pla
		lsr	a
		lsr	a
		lsr	a
		lsr	a
$$ltoasc	and	#%00001111
		cmp	#$0a
		bcc	$$ltoasc_nc
		adc	#6			;6+Cy(1)
$$ltoasc_nc	adc	#$30			;0..9 -> "0".."9", A..F -> "A".."F"
		rts
    ENDIF
;	Print exit string:
program_exit	jsr	rom_primm
    IF (target_platform == 20)
		BYT	ascii_return,"-- '",prg_name,"' END",0
    ELSE
		BYT	ascii_return,"--- TEST '",prg_name,"' END.",0
    ENDIF
		rts
;	Print ID string:
start_continue	jsr	rom_primm
		BYT	ascii_return,ascii_return,"VCPU TST V",def_testcodes_version
		BYT	"/",targetstring
    IF (target_platform <> 20)
		BYT	" --- '",prg_name,"'"
    ENDIF
		BYT	ascii_return,0
;------------------------------------------------------------------------------
