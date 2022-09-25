;------------------------------------------------------------------------------
;---	Print memory contents
;------------------------------------------------------------------------------
    IF target_platform = 20
bytesofline	set	4
    ELSE
bytesofline	set	8
    ENDIF
;------------------------------------------------------------------------------
;---	Set address for display:
;---	Y:X <- Hi:Lo address for display

printmem_setdispaddr

		stx	_displayaddr+0
		sty	_displayaddr+1
		rts
;------------------------------------------------------------------------------
;---	Print memory contents:
;---	Y:X <- Hi:Lo memory pointer
;---	A   <- Number of displayable BYTEs

printmem	sta	$$byteno		;Save BYTE no
		stx	z_eal
		sty	z_eah			;Save address

$$printcycle	lda	$$byteno
		bne	$$printing
		rts				;If no any BYTEs, end
$$printing	sec
		sbc	#bytesofline
		bcs	$$eigthormore
		lda	$$byteno
		sta	$$printno
		lda	#0
		sta	$$byteno
		beq	$$printline
$$eigthormore	sta	$$byteno
		lda	#bytesofline
		sta	$$printno

$$printline	jsr	rom_primm
		BYT	ascii_return,"*",0
		lda	_displayaddr+1
		jsr	mon_puthex
		lda	_displayaddr+0
		jsr	mon_puthex
		ldx	$$printno
    IF target_platform = 20
		lda	#' '
		jsr	rom_bsout
    ENDIF
		ldy	#0
$$printdatas
    IF target_platform <> 20
		lda	#' '
		jsr	rom_bsout
    ENDIF
		lda	(z_eal),y
		jsr	mon_puthex
		iny
		dex
		bne	$$printdatas

		lda	#bytesofline
		sec
		sbc	$$printno
		beq	$$printascii
		tax
$$printtrimdat	jsr	rom_primm
    IF target_platform = 20
		BYT	"  ",0
    ELSE
		BYT	"   ",0
    ENDIF
		dex
		bne	$$printtrimdat
$$printascii	jsr	rom_primm
		BYT	" :",ascii_rvson,0
		ldx	$$printno
		ldy	#0
$$printascii_cy	lda	(z_eal),y
		and	#%01111111
		cmp	#$20
		lda	(z_eal),y
		bcs	$$ascii_ok
		lda	#'.'
$$ascii_ok	jsr	rom_bsout
		iny
		dex
		bne	$$printascii_cy

		lda	_displayaddr+0
		clc
		adc	$$printno
		sta	_displayaddr+0
		bcc	$$nocy_1
		inc	_displayaddr+1
$$nocy_1	lda	z_eal
		clc
		adc	$$printno
		sta	z_eal
		bcc	$$nocy_2
		inc	z_eah
$$nocy_2	jmp	$$printcycle

$$byteno	BYT	0
$$printno	BYT	0
;------------------------------------------------------------------------------
_displayaddr	ADR	$ffff
;------------------------------------------------------------------------------
