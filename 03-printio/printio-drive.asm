;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.17.+ by BSZ
;---	Print I/O area - drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
drivecode_sptr		=	drivecode_start + $000
;------------------------------------------------------------------------------
	ORG	drivecode_start
drive_iosize	BYT	0				;<- Replace host to I/O size

drivecode_go	ldzph	hi(drivecode_zptr)		;Set ZPH
		ldsph	hi(drivecode_sptr)		;Set SPH
		ldx	#$ff
		txs					;Set SP

		ldx	#0
$$iordcyc	lda	vcpu_iobase,x
		sta	readeddatas,x
		inx
		cpx	drive_iosize
		bne	$$iordcyc
		break	vcpu_syscall_exit_ok
;------------------------------------------------------------------------------
readeddatas	;RMB 16/22...
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_go
	SHARED	readeddatas
;------------------------------------------------------------------------------
