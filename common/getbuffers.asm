;------------------------------------------------------------------------------
;---	Get buffer status
;------------------------------------------------------------------------------
    IFNDEF displaylevel
displev		SET	0
    ELSE
displev		SET	displaylevel
    ENDIF
;------------------------------------------------------------------------------
sd2i_getbuffers

		ldx	#lo($$chkcomm)
		ldy	#hi($$chkcomm)
		lda	#$$chkcomm_end-$$chkcomm
		jsr	sd2i_sendcommand		;Send "ZB" command
		ldx	#lo(_bufferstates)
		ldy	#hi(_bufferstates)
		lda	#_bufferstates_end-_bufferstates
		jsr	sd2i_recvanswer			;Receive answer, Y = number of readed bytes
		sty	_buffst_byteno			;Save length for later use

    IF displev < 1
		lda	#0
		sta	$$bufferno
$$nextbuffer	lda	$$bufferno
		lsr	a				;/2
		tax
		lda	#0
		jsr	rom_primm
		BYT	ascii_return,"BUF #",0
		jsr	bas_linprt
		ldy	$$bufferno
		lda	_bufferstates+0,y
		and	#%00000001			;Only Allocated/Free bit remain
		beq	$$bufferfree
		jsr	rom_primm
		BYT	": USED (",0
		jmp	$$cont
$$bufferfree	jsr	rom_primm
		BYT	": FREE (",0
$$cont		ldx	_bufferstates+1,y
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
    IF target_platform == 20
		BYT	": CH)",0
    ELSE
		BYT	": CHN)",0
    ENDIF
		ldx	$$bufferno
		inx
		inx
		stx	$$bufferno
		cpx	_buffst_byteno			;End?
		bne	$$nextbuffer
    ENDIF
		rts

$$chkcomm	BYT	"ZB"
$$chkcomm_end
$$bufferno	BYT	0

_bufferstates	BYT	0,0,0,0,0,0,0,0
		BYT	0,0,0,0,0,0,0,0
		BYT	0,0,0,0,0,0,0,0
		BYT	0,0,0,0,0,0			;30 BYTEs: 15 buffers max
_bufferstates_end
_buffst_byteno	BYT	0				;Number of BYTEs
;------------------------------------------------------------------------------
displev		SET	0
;------------------------------------------------------------------------------
