;------------------------------------------------------------------------------
;---	Wait time
;------------------------------------------------------------------------------
;---	Wait number of frames (interrupts)
;---	Use system time
;---	X <- Number of frames (interrupts)

wait_frames	lda	z_time+2
$$wait		cmp	z_time+2
		beq	$$wait
		dex
		cpx	#$ff
		bne	wait_frames
		rts
;------------------------------------------------------------------------------
