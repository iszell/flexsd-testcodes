;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.12.+ by BSZ
;---	Buttons + LEDs, drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
drivecode_sptr		=	drivecode_start + $000
;------------------------------------------------------------------------------
	ORG	drivecode_start

		ldzph	hi(drivecode_zptr)		;Set ZPH
		ldsph	hi(drivecode_sptr)		;Set SPH
		ldx	#$ff
		txs					;Set SP
$$cycle		lda	vcpu_hid			;B76: Buttons, B10: LEDs
		eor	vcpu_clkdatin			;CLK / DAT lines
		rol	a
		rol	a
		rol	a				;B76 -> B10
		sta	vcpu_hid

;	UART debug test
;	  (Only useful when the drive firmware compiled in uart debug mode,
;	   otherwise ineffective)
		clv
		lda	vcpu_dbguart
		bvc	$$cycle
		sta	vcpu_dbguart
		cmp	#13
		bne	$$cycle
		lda	#10
		sta	vcpu_dbguart
		jmp	$$cycle
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
