;------------------------------------------------------------------------------
;---	Get SD2IEC Long version string
;------------------------------------------------------------------------------
sd2i_printlongversion

		jsr	rom_primm
		BYT	ascii_return,"LONG VERSION: ",0

		ldx	#lo($$commstr)
		ldy	#hi($$commstr)
		lda	#$$commstr_end-$$commstr
		jsr	sd2i_sendcommand	;Send "X?" command
		jmp	sd2i_printstatus

$$commstr	BYT	"X?"
$$commstr_end
;------------------------------------------------------------------------------
