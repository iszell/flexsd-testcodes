;------------------------------------------------------------------------------
;---	Get status from drive and print
;------------------------------------------------------------------------------
;---	Get and print drive's status:
;---	A   -> Status code in BCD
;---	Cy. -> 0: OK, 1: error (maybe "DEVICE NOT PRESENT")

sd2i_printstatus

		lda	#%00000000
		sta	z_status
		lda	z_fa			;Unit No
		jsr	rom_talk
		lda	z_status
		bne	$$devmiss
		lda	#$6f			;Error channel
		sta	z_sa
		jsr	rom_tksa
		lda	z_status
		beq	$$devokay
$$devmiss	lda	#$ff
		sec				;SEC: Device error (maybe "DEVICE NOT PRESENT")
		rts
$$devokay	jsr	rom_acptr
		sta	$$statuscode+0
		jsr	rom_bsout
		jsr	rom_acptr
		sta	$$statuscode+1
		jsr	rom_bsout
		ldy	#0
$$readdata	bit	z_status
		bvs	$$dataend
		jsr	rom_acptr
		cmp	#ascii_return
		beq	$$noretprint
		jsr	rom_bsout
$$noretprint	iny
		bne	$$readdata
$$dataend	jsr	rom_untlk
		lda	$$statuscode+0
		asl	a
		asl	a
		asl	a
		asl	a
		sta	$$statuscode+0
		lda	$$statuscode+1
		and	#%00001111
		ora	$$statuscode+0		;Return status code in BCD
		clc				;CLC: OK
		rts

$$statuscode	BYT	0,0
;------------------------------------------------------------------------------
