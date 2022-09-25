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

    IF displev < 2
		jsr	rom_primm
		BYT	ascii_return,"  PC:",0
		lda	_vcpustatus+1
		jsr	mon_puthex
		lda	_vcpustatus+0
		jsr	mon_puthex			;"PC" HI+LO

		jsr	rom_primm
		BYT	ascii_return,"  A:",0
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
		BYT	ascii_return,"  SR:",0
		lda	_vcpustatus+5
		jsr	mon_puthex			;"SR"

		jsr	rom_primm
		BYT	ascii_return,"  SP:",0
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
		BYT	ascii_return,"  INT:",0
		lda	_vcpustatus+9
		jsr	mon_puthex			;"INT"
		jsr	rom_primm
		BYT	" FUNCT:",0
		lda	_vcpustatus+10
		jsr	mon_puthex			;"FUNCT"
		jsr	rom_primm
		BYT	" LASTOP:",0
		lda	_vcpustatus+11
		jsr	mon_puthex			;"LASTOP"
    ENDIF
		rts

$$chkcomm	BYT	"ZC"
$$chkcomm_end

_vcpustatus	BYT	0,0,0,0,0,0,0,0
		BYT	0,0,0,0,0,0,0,0			;16 BYTEs (12 used)
_vcpustatus_end
;------------------------------------------------------------------------------
displev		SET	0
;------------------------------------------------------------------------------
