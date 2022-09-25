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
		jsr	rom_primm
		BYT	ascii_return,"VCPU VERSION:",0
		and	#%00011111			;Only version number remain
		tax
		lda	#0
		jsr	bas_linprt
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
    ENDIF
		lda	$$infodata+3			;VCPU memory size
		clc					;CLC: VCPU support ok
		rts

$$chkcomm	BYT	"ZI"
$$chkcomm_end
$$infodata	BYT	0,0,0,0,0,0,0,0
$$infodata_end
;------------------------------------------------------------------------------
displev		SET	0
;------------------------------------------------------------------------------
