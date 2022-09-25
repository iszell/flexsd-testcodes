;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.04.+ by BSZ
;---	Line diagnostics - drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
drivecode_sptr		=	drivecode_start + $000
;------------------------------------------------------------------------------
	ORG	drivecode_start

;	DAT:
		ldzph	hi(drivecode_zptr)		;Set ZPH
		ldsph	hi(drivecode_sptr)		;Set SPH
		ldx	#$ff
		txs					;Set SP

		break	vcpu_syscall_disableatnirq

		uwath
		uwckh
		uwdth

		lda	#%11100000
		utest
		sta	vcpu_errorbuffer+0
		stx	vcpu_errorbuffer+1
		sty	vcpu_errorbuffer+2
		tsx
		stx	vcpu_errorbuffer+3
		lda	#%01111111
		utest
		sta	vcpu_errorbuffer+4
		stx	vcpu_errorbuffer+5
		sty	vcpu_errorbuffer+6
		tsx
		stx	vcpu_errorbuffer+7
		lda	#%11100000
		utest
		sta	vcpu_errorbuffer+8
		stx	vcpu_errorbuffer+9
		sty	vcpu_errorbuffer+10
		tsx
		stx	vcpu_errorbuffer+11

;	CLK:
		lda	#%11100000
		utest
		sta	vcpu_errorbuffer+12
		stx	vcpu_errorbuffer+13
		sty	vcpu_errorbuffer+14
		tsx
		stx	vcpu_errorbuffer+15
		lda	#%10111111
		utest
		sta	vcpu_errorbuffer+16
		stx	vcpu_errorbuffer+17
		sty	vcpu_errorbuffer+18
		tsx
		stx	vcpu_errorbuffer+19
		lda	#%11100000
		utest
		sta	vcpu_errorbuffer+20
		stx	vcpu_errorbuffer+21
		sty	vcpu_errorbuffer+22
		tsx
		stx	vcpu_errorbuffer+23

;	ATN:
		lda	#%11100000
		utest
		sta	vcpu_errorbuffer+24
		stx	vcpu_errorbuffer+25
		sty	vcpu_errorbuffer+26
		tsx
		stx	vcpu_errorbuffer+27
		lda	#%11011111
		utest
		sta	vcpu_errorbuffer+28
		stx	vcpu_errorbuffer+29
		sty	vcpu_errorbuffer+30
		tsx
		stx	vcpu_errorbuffer+31
		lda	#%11100000
		utest
		sta	vcpu_errorbuffer+32
		stx	vcpu_errorbuffer+33
		sty	vcpu_errorbuffer+34
		tsx
		stx	vcpu_errorbuffer+35

		ldx	#36				;36 BYTEs in Error buffer
		break	vcpu_syscall_exit_fillederror
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
