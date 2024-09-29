;------------------------------------------------------------------------------
;---	Get VCPU status
;------------------------------------------------------------------------------
    IFNDEF displaylevel
displev		SET	0
    ELSE
displev		SET	displaylevel
    ENDIF
;------------------------------------------------------------------------------
sd2i_getvcpustatus

		ldx	#lo($$chkcomm)
		ldy	#hi($$chkcomm)
		lda	#$$chkcomm_end-$$chkcomm
		jsr	sd2i_sendcommand		;Send "ZC" command
		ldx	#lo(_vcpustatus)
		ldy	#hi(_vcpustatus)
		lda	#_vcpustatus_end-_vcpustatus
		jsr	sd2i_recvanswer			;Recv answer, Y = number of readed bytes
		sty	_vcpustatus_siz			;Store status size

    IF displev < 2
		jsr	rom_primm
		BYT	ascii_return," PC:",0
		lda	_vcpustatus+1
		ldx	_vcpustatus+0
		jsr	$$printhexword			;"PC" HI+LO

		jsr	rom_primm
		BYT	" SR:%",0
		ldy	#7
		lda	_vcpustatus+5			;"SR"
$$binconv	ldx	#'0'
		asl	a
		bcc	$$bc_b0
		ldx	#'1'
$$bc_b0		pha
		txa
		jsr	rom_bsout
		pla
		dey
		bpl	$$binconv

		jsr	rom_primm
		BYT	ascii_return," A:",0
		lda	_vcpustatus+2
		jsr	mon_puthex			;"A"
		jsr	rom_primm
		BYT	" X:",0
		lda	_vcpustatus+3
		jsr	mon_puthex			;"X"
		jsr	rom_primm
		BYT	" Y:",0
		lda	_vcpustatus+4
		jsr	mon_puthex			;"X"

		jsr	rom_primm
		BYT	ascii_return," SP:",0
		lda	_vcpustatus+6
		jsr	mon_puthex			;"SP"
		jsr	rom_primm
		BYT	" SPH:",0
		lda	_vcpustatus+7
		jsr	mon_puthex			;"SPH"
		jsr	rom_primm
		BYT	" ZPH:",0
		lda	_vcpustatus+8
		jsr	mon_puthex			;"ZPH"

		jsr	rom_primm
		BYT	ascii_return," INT:",0
		lda	_vcpustatus+9
		jsr	mon_puthex			;"INT"
		jsr	rom_primm
		BYT	" FNC:",0
		lda	_vcpustatus+10
		jsr	mon_puthex			;"FUNCT"
		jsr	rom_primm
		BYT	" LOP:",0
		lda	_vcpustatus+11
		jsr	mon_puthex			;"LASTOP"

		lda	_vcpustatus_siz
		cmp	#18				;"R2" length?
		bcc	$$nouservect
		jsr	rom_primm
		BYT	ascii_return," RR:",0
		lda	_vcpustatus+13
		ldx	_vcpustatus+12
		jsr	$$printhexword			;"RR"
		jsr	rom_primm
    IF target_platform == 20
		BYT	ascii_return
    ENDIF
		BYT	" U1R:",0
		lda	_vcpustatus+15
		ldx	_vcpustatus+14
		jsr	$$printhexword			;"U1R"
		jsr	rom_primm
		BYT	" U2R:",0
		lda	_vcpustatus+17
		ldx	_vcpustatus+16
		jsr	$$printhexword			;"U2R"
$$nouservect
    ENDIF
		rts

    IF displev < 2
;	Print WORD in hex:
;	A:X <- WORD
$$printhexword	jsr	mon_puthex
		txa
		jmp	mon_puthex
    ENDIF

$$chkcomm	BYT	"ZC"
$$chkcomm_end

_vcpustatus_siz	BYT	0
_vcpustatus	BYT	0,0,0,0,0,0,0,0
		BYT	0,0,0,0,0,0,0,0			;16 BYTEs (12 used in VCPU R1)
		BYT	0,0,0,0				;20 BYTEs (18 used in VCPU R2)
_vcpustatus_end
;------------------------------------------------------------------------------
displev		SET	0
;------------------------------------------------------------------------------
