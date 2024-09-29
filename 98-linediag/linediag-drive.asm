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

		ldy	#0			;Result offset init

		lda	#%11110000
		sta	vcpu_diag
		jsr	copyresult
		lda	#%01110000
		sta	vcpu_diag
		jsr	copyresult
		lda	#%11110000
		sta	vcpu_diag
		jsr	copyresult

;	CLK:
		lda	#%11110000
		sta	vcpu_diag
		jsr	copyresult
		lda	#%10110000
		sta	vcpu_diag
		jsr	copyresult
		lda	#%11110000
		sta	vcpu_diag
		jsr	copyresult

;	ATN:
		lda	#%11110000
		sta	vcpu_diag
		jsr	copyresult
		lda	#%11010000
		sta	vcpu_diag
		jsr	copyresult
		lda	#%11110000
		sta	vcpu_diag
		jsr	copyresult

;	SRQ:
		lda	vcpu_version
		and	#%00011111			;Only VCPU version remain
		cmp	#2				;R2? (Fast Serial support...)
		bcc	$$nofastser
		lda	#%11110000
		sta	vcpu_diag
		jsr	copyresult
		lda	#%11100000
		sta	vcpu_diag
		jsr	copyresult
		lda	#%11110000
		sta	vcpu_diag
		jsr	copyresult
$$nofastser
		tya
		tax					;X = 36 BYTEs in Error buffer
		dey
$$move		lda	resultdata,y
		sta	vcpu_errorbuffer,y
		dey
		bpl	$$move

		;ldx	#36				;X = 36 / 48 BYTEs in Error buffer
		break	vcpu_syscall_exit_fillederror

;	Copy result:
;	Y <- start pos
;	Y -> end pos
copyresult	ldx	#0
.copy		lda	vcpu_errorbuffer,x
		sta	resultdata,y
		iny
		inx
		cpx	#4
		bne	.copy
		rts

resultdata	RMB	4*3*3			;4×3×3 BYTES

;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
