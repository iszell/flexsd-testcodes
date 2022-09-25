;------------------------------------------------------------------------------
;---	SD2IEC VCPU memory execute, simple version
;------------------------------------------------------------------------------
;---	Y:X <- VCPU start address

sd2i_execmemory_simple

		stx	$$startlo+1
		sty	$$starthi+1
		lda	#%00000000
		sta	z_status
		lda	z_fa			;Unit No
		jsr	rom_listn
		lda	#$6f			;Command channel
		sta	z_sa
		jsr	rom_secnd
		lda	#'Z'
		jsr	rom_ciout
		lda	#'E'
		jsr	rom_ciout
$$startlo	lda	#$ff
		jsr	rom_ciout
$$starthi	lda	#$ff
		jsr	rom_ciout		;"ZE" + Drivecode start address
		jmp	rom_unlsn
;------------------------------------------------------------------------------
