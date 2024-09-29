;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.03.21.+ by BSZ
;---	Serial lines stress test, drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
drivecode_sptr		=	drivecode_start + $000
;------------------------------------------------------------------------------
	ORG	drivecode_start
_mode		BYT	0				;Mode: B0=1: ATN, B1=1: CLK, B2=1: DAT
_default	BYT	%11111100			;Lines Start state, ATN released, CLK/DAT pulled low

drivecode_go	break	vcpu_syscall_disableatnirq	;Disable ATN IRQ
		lda	_default
		sta	vcpu_atnsrqout			;B7 = ATN state
		sta	vcpu_clkdatout			;B1 = DAT state, B0 = CLK state: Set lines default state
		ldzph	hi(drivecode_zptr)
		ldsph	hi(drivecode_sptr)
		ldx	#lo(drivecode_sptr + $ff)
		txs

		lda	#%00000011
		sta	vcpu_hid			;LEDs ON
$$cycle		lda	vcpu_atnsrqout
		eor	_mode
		sta	vcpu_atnsrqout
		lda	vcpu_clkdatout
		eor	_mode
		sta	vcpu_clkdatout			;Flip seletced lines state
		bit	vcpu_hid			;B7 = NEXT ( -> "N" flag) B6 = PREV ( -> "V" flag)
		bpl	$$cycle				;NEXT not pressed, cycle...

		ldx	#$ff
$$buttonpress	udely	$ff				;Wait a moment
		bit	vcpu_hid			;B7 = NEXT ( -> "N" flag) B6 = PREV ( -> "V" flag)
		bpl	$$cycle				;NEXT not pressed, cycle...
		dex
		bne	$$buttonpress

		lda	#%00000010
		sta	vcpu_hid			;BUSY LED OFF
$$waitrest	ldx	#$ff
$$wait		udely	$ff				;Wait a moment
		bit	vcpu_hid			;B7 = NEXT ( -> "N" flag) B6 = PREV ( -> "V" flag)
		bmi	$$waitrest			;NEXT pressed, wait...
		dex
		bne	$$wait

;	Exit:
		lda	#%00000000
		sta	vcpu_hid			;LEDs OFF
		break	vcpu_syscall_exit_ok
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_go
;------------------------------------------------------------------------------
