;------------------------------------------------------------------------------
;---	Wait a key
;------------------------------------------------------------------------------
;---	Wait any (printable) key
;---	A -> ASCII code of pressed key

wait_keypress	lda	#0
		sta	z_ndx		;Clear Interrupt's keyboard buffer
$$wait		lda	z_ndx
		beq	$$wait
		lda	_keyd+0		;Get ASCII code of pressed key
		pha
		lda	#0
		sta	z_ndx
		pla
		rts
;------------------------------------------------------------------------------
