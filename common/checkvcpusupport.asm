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
$$vcpuready
    IF displev < 1
		sty	$$answerlength+1		;Modify the number of received BYTEs
		jsr	rom_primm
		BYT	ascii_return,"VCPU VERSION:",0
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
		ldx	$$infodata+1
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
		BYT	ascii_return,"  ERROR B. SIZE:",0
		ldx	$$infodata+2
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
		BYT	ascii_return,"  BLOCK BUFFERS NO:",0
		ldx	$$infodata+3
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
		BYT	ascii_return,"  I/O AREA SIZE:",0
$$answerlength	lda	#$00				;<- DRIVE's answer length, modified previously
		cmp	#5
		bcc	$$noioarea
		ldx	$$infodata+4
		inx
		lda	#0
		jsr	bas_linprt
		jmp	$$ready
$$noioarea	jsr	rom_primm
		BYT	"UKNW",0
    ENDIF
$$ready		lda	$$infodata+3			;VCPU memory size
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
;------------------------------------------------------------------------------
displev		SET	0
;------------------------------------------------------------------------------
