;------------------------------------------------------------------------------
;---	Get status from drive and print
;------------------------------------------------------------------------------
;---	Get and print drive's status:
;---	A -> Status code in BCD

sd2i_printstatus

		lda	#%00000000
		sta	z_status
		lda	z_fa			;Unit No
		jsr	rom_talk
		lda	#$6f			;Error channel
		sta	z_sa
		jsr	rom_tksa

		jsr	rom_acptr
		sta	$$statuscode+0
		jsr	rom_bsout
		jsr	rom_acptr
		sta	$$statuscode+1
		jsr	rom_bsout
		ldy	#0
$$readdata	bit	z_status
		bvs	$$dataend
		jsr	rom_acptr
		jsr	rom_bsout
		iny
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
		rts
$$statuscode	BYT	0,0
;------------------------------------------------------------------------------
