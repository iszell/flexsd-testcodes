;------------------------------------------------------------------------------
;---	Get buffer status
;------------------------------------------------------------------------------
sd2i_getbuffers

		ldx	#lo($$chkcomm)
		ldy	#hi($$chkcomm)
		lda	#$$chkcomm_end-$$chkcomm
		jsr	sd2i_sendcommand		;Send "ZB" command
		ldx	#lo($$bufferdata)
		ldy	#hi($$bufferdata)
		lda	#$$bufferdata_end-$$bufferdata
		jsr	sd2i_recvanswer			;Receive answer, Y = number of readed bytes
		sty	$$bufcountcmp+1

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
		lda	$$bufferdata+0,y
		and	#%00000001			;Only Allocated/Free bit remain
		beq	$$bufferfree
		jsr	rom_primm
		BYT	": USED (",0
		jmp	$$cont
$$bufferfree	jsr	rom_primm
		BYT	": FREE (",0
$$cont		ldx	$$bufferdata+1,y
		lda	#0
		jsr	bas_linprt
		jsr	rom_primm
		BYT	": CHN)",0
		ldx	$$bufferno
		inx
		inx
		stx	$$bufferno
$$bufcountcmp	cpx	#$ff				;Self-modified code: end?
		bne	$$nextbuffer
		rts

$$chkcomm	BYT	"ZB"
$$chkcomm_end
$$bufferno	BYT	0
$$bufferdata	BYT	0,0,0,0,0,0,0,0
		BYT	0,0,0,0,0,0,0,0
		BYT	0,0,0,0,0,0,0,0
		BYT	0,0,0,0,0,0			;30 BYTEs: 15 buffers max
$$bufferdata_end
;------------------------------------------------------------------------------
