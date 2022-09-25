;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.19.+ by BSZ
;---	Send/Receive test, 1bit, drive side
;---	USND1/URCV1 commands on drive side, preferred communication method
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
drivecode_sptr		=	drivecode_start + $000
;------------------------------------------------------------------------------
	ORG	drivecode_start

		usdtl					;Drive DAT
		ldzph	hi(_drive_databuffer)		;Set ZPH
		ldsph	hi(drivecode_sptr)		;Set SPH
		ldx	#$ff
		txs					;Set SP

$$bigcycle	ldy	#$ff				;256 BYTEs receive/send back
		urcv1					;Get BYTE
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		ldx	#$00
$$recvcyc	urcv1					;Get BYTE
		sta	lo(_drive_databuffer),x		;Save to buffer
		uindb	$$recvcyc			;X+, Y-, jump back
$$sendcyc	lda	lo(_drive_databuffer),x		;Load from buffer
		usnd1					;Send BYTE
		uindb	$$sendcyc			;X+, Y-, jump back
		uwckh					;Wait for CLK HIGH
		usdtl					;Drive DAT
		jmp	$$bigcycle
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
