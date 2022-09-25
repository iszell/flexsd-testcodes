;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.04.+ by BSZ
;---	Receive time test, 1bit, drive side
;---	USND1 command on drive side, preferred communication method
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $100
drivecode_sptr		=	drivecode_start + $000
;------------------------------------------------------------------------------
	ORG	drivecode_start

		ucldl					;Drive CLK/DAT
		ldzph	hi(_drive_databuffer)
		ldsph	hi(drivecode_sptr)
		ldx	#lo(drivecode_sptr + $ff)
		txs

$$bigcycle	ldx	#0
$$gendata	txa
		sta	$00,x
		inx
		bne	$$gendata
$$bigcycle2	urcv1					;Get BYTE
		ucldl					;Drive CLK/DAT
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		tay					;x BYTE
		ldx	$$datastart
		lda	$$datastart
		and	#%11111110			;First DAT bit = LOW
		usnd1					;Send BYTE
$$sendcyc	lda	$00,x
		usnd1					;Send BYTE
		uindb	$$sendcyc
		uwckh					;Wait for CLK HIGH
		ucldl					;Drive CLK/DAT
		inc	$$datastart
		jmp	$$bigcycle2

$$datastart	BYT	$00
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
