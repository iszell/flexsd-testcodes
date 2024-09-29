;------------------------------------------------------------------------------
;---	Check SD2IEC VCPU support
;------------------------------------------------------------------------------
    IFNDEF displaylevel
displev		SET	0
    ELSE
displev		SET	displaylevel
    ENDIF
;------------------------------------------------------------------------------
;---	A   -> VCPU memory size in 256 BYTEs block
;---	Cy. -> 0: VCPU support present
;---	       1: No VCPU support

sd2i_checkvcpusupport

		lda	#0
		sta	_vcpu_version
		sta	_vcpu_commandch_size
		sta	_vcpu_errorch_size
		sta	_vcpu_memory_size
		sta	_vcpu_ioarea_size
		ldx	#lo($$chkcomm)
		ldy	#hi($$chkcomm)
		lda	#$$chkcomm_end-$$chkcomm
		jsr	sd2i_sendcommand		;Send "ZI" command
		ldx	#lo($$infodata)
		ldy	#hi($$infodata)
		lda	#$$infodata_end-$$infodata
		jsr	sd2i_recvanswer			;Recv answer
		lda	$$infodata+0			;First byte from answer
		cmp	#'3'				;"30, SYNTAX ERROR..." char?
		bne	$$vcpuready
    IF displev < 2
		jsr	rom_primm
		BYT	ascii_return,"NO VCPU SUPPORT",0
    ENDIF
		sec					;SEC: No VCPU support
		rts

$$vcpuready	sta	_vcpu_version			;Save VCPU version code
		cpy	#5
		bcc	$$noioarea
		ldx	$$infodata+4
		inx
		stx	_vcpu_ioarea_size
$$noioarea	ldx	$$infodata+1
		stx	_vcpu_commandch_size
		ldx	$$infodata+2
		stx	_vcpu_errorch_size
		ldx	$$infodata+3
		stx	_vcpu_memory_size

    IF displev < 1
		jsr	rom_primm
		BYT	ascii_return,"VCPU VERSION:R",0
		and	#%00011111			;Only version number remain
		tax
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
		BYT	ascii_return,"BUS TYPE:",0
		lda	$$infodata+0
		jsr	$$printbustype
		jsr	rom_primm
		BYT	ascii_return,"  COMMAND B. SIZE:",0
		ldx	_vcpu_commandch_size
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
		BYT	ascii_return,"  ERROR B. SIZE:",0
		ldx	_vcpu_errorch_size
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
		BYT	ascii_return,"  BLOCK BUFFERS NO:",0
		ldx	_vcpu_memory_size
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
		BYT	ascii_return,"  I/O AREA SIZE:",0
		ldx	_vcpu_ioarea_size
		beq	$$unknioarea
		lda	#0
		jsr	bas_linprt
		jmp	$$ready

$$unknioarea	jsr	rom_primm
		BYT	"UKNW",0
    ENDIF
$$ready		lda	_vcpu_ioarea_size
		bne	$$iosizeset
		lda	#16
		sta	_vcpu_ioarea_size		;Old fw not report I/O area size, 16 set
$$iosizeset	lda	_vcpu_memory_size		;VCPU memory size
		clc					;CLC: VCPU support ok
		rts

    IF displev < 1
;	Print BUS type:
;	A <- VCPU version number, B765 = BUS type:
$$printbustype	lsr	a
		lsr	a
		lsr	a
		lsr	a			;B765 shifted to B321
		and	#%00001110
		tax
		lda	$$typetable+1,x		;Addr Hi
		pha
		lda	$$typetable+0,x		;Addr Lo
		pha
		rts				;Jump to type-display
;	Communication bus names:
$$typetable	ADR	$$typeu-1
		ADR	$$type1-1
		ADR	$$type2-1
		ADR	$$type3-1
		ADR	$$type4-1
		ADR	$$type5-1
		ADR	$$type6-1
		ADR	$$typeu-1

$$typeu		jsr	rom_primm
		BYT	"UNKNOWN",0
		rts
$$type1		jsr	rom_primm
		BYT	"IEEE-488",0
		rts
$$type2		jsr	rom_primm
		BYT	"SERIAL",0
		rts
$$type3		jsr	rom_primm
		BYT	"FASTSER",0
		rts
$$type4		jsr	rom_primm
		BYT	"SERIAL+PAR",0
		rts
$$type5		jsr	rom_primm
		BYT	"FASTSER+PAR",0
		rts
$$type6		jsr	rom_primm
		BYT	"TCBM",0
		rts
    ENDIF

$$chkcomm	BYT	"ZI"
$$chkcomm_end
$$infodata	BYT	0,0,0,0,0,0,0,0
$$infodata_end

_vcpu_version		BYT	0
_vcpu_commandch_size	BYT	0
_vcpu_errorch_size	BYT	0
_vcpu_memory_size	BYT	0
_vcpu_ioarea_size	BYT	0
;------------------------------------------------------------------------------
displev		SET	0
;------------------------------------------------------------------------------
