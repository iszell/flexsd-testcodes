;------------------------------------------------------------------------------
;---	Check data and others
;------------------------------------------------------------------------------
;---	Clear screen for data checking:

fillscreenfordata

		ldx	#0
$$scnclr	lda	#' '
		sta	screen_addr+scrclr_offset,x
		lda	#'.'
		sta	screen_addr,x
		lda	_color
		sta	color_addr+scrclr_offset,x
		sta	color_addr,x
		inx
		bne	$$scnclr
		rts
;------------------------------------------------------------------------------
;---	Check received data:
;---	A   <- First BYTE value
;---	Y   <- Start checking position
;---	Cy. -> 0: OK
;---	       1: ERROR

datachecker	ldx	#0

$$comparecyc	cmp	screen_addr,y
		bne	$$comparerror
$$comperrcont	clc
		adc	#1
		iny
		bne	$$comparecyc
		cpx	#0
		bne	$$errordisplay
		clc				;CLC: OK
		rts
$$comparerror	inx				;Count
		bne	$$compnovf
		dex
$$compnovf	pha
		lda	#error_color
		sta	color_addr,y		;Change character color
		pla
		jmp	$$comperrcont

$$errordisplay	jsr	rom_primm
		BYT	"COMPARE ERROR!       ",0
		sec				;SEC: ERROR
		rts
;------------------------------------------------------------------------------
