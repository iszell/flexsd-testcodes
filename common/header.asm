;------------------------------------------------------------------------------
;---	BASIC header (and others)
;------------------------------------------------------------------------------
    IF target_platform = 20
      IF vic20_setmem = 0
start_addr	=	$1001
      ELSEIF vic20_setmem = 3
start_addr	=	$0401
      ELSEIF vic20_setmem = 8
start_addr	=	$1201
      ELSE
	ERROR "No correct VIC20 memory size definied!"
      ENDIF
    ELSEIF target_platform = 64
start_addr	=	$0801
    ELSEIF target_platform = 264
start_addr	=	$1001
    ELSEIF target_platform = 128
start_addr	=	$1c01
    ENDIF

	ORG	start_addr - 2
		ADR	start_addr
		ADR	$$basend, 2021
		BYT	$9e
		BYT	$30 + ((start_continue # 10000) / 1000)
		BYT	$30 + ((start_continue # 1000) / 100)
		BYT	$30 + ((start_continue # 100) / 10)
		BYT	$30 + ((start_continue # 10) / 1)
$$basend	BYT	0,0,0

    IF (target_platform = 20) || (target_platform = 64)
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
start_continue
;------------------------------------------------------------------------------
