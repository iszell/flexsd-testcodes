;------------------------------------------------------------------------------
;---	Command / Error channel routines
;------------------------------------------------------------------------------
;---	Send data to command channel:
;---	Y:X <- Command bytes in memory
;---	A   <- Command length

sd2i_sendcommand

		sta	$$sendlen+1
		stx	$$sendstring+1
		sty	$$sendstring+2

		lda	#%00000000
		sta	z_status
		sta	z_c3po
		sta	z_r2d2
		lda	z_fa			;Unit No
		jsr	rom_listn
		lda	#$6f			;Command channel
		sta	z_sa
		jsr	rom_secnd
		ldy	#0
$$sendstring	lda	$ffff,y
		jsr	rom_ciout
		iny
$$sendlen	cpy	#$ff
		bne	$$sendstring
		jmp	rom_unlsn
;------------------------------------------------------------------------------
;---	Receive data from error channel:
;---	Y:X <- Readed bytes Memory address
;---	A   <- Maximum number of readed bytes
;---	Y   -> Number of readed bytes (or maximum, if more data received)

sd2i_recvanswer
		sta	$$recvlen+1
		stx	$$recvaddr+1
		sty	$$recvaddr+2

		lda	#%00000000
		sta	z_status
		lda	z_fa			;Unit No
		jsr	rom_talk
		lda	#$6f			;Error channel
		sta	z_sa
		jsr	rom_tksa
		ldy	#0
$$readdata	bit	z_status
		bvs	$$datasend
		jsr	rom_acptr
$$recvlen	cpy	#$ff
		beq	$$readdata		;If too much data received, not store
$$recvaddr	sta	$ffff,y
		iny
		bne	$$readdata		;~BRA
$$datasend	jmp	rom_untlk
;------------------------------------------------------------------------------
