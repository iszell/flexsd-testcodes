;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Send/Receive test, 2bit, drive side
;---	USND2/URCV2 commands on drive side, preferred communication method
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_sptr		=	drivecode_start + $000
;------------------------------------------------------------------------------
	ORG	drivecode_start

		ucldl					;Drive CLK/DAT

		ldzph	hi(_drive_databuffer)		;Set ZPH
		ldsph	hi(drivecode_sptr)		;Set SPH
		ldx	#$ff
		txs					;Set SP

		break	vcpu_syscall_disableatnirq	;Disable ATN IRQ

$$bigcycle	ldy	#$ff				;256 BYTEs receive/send back
		urcv2					;Get BYTE
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		ldx	#$00
$$recvcyc	urcv2					;Get BYTE
		sta	lo(_drive_databuffer),x		;Save to buffer
		uindb	$$recvcyc			;X+, Y-, jump back
$$sendcyc	lda	lo(_drive_databuffer),x		;Load from buffer
		usnd2					;Send BYTE
		uindb	$$sendcyc			;X+, Y-, jump back
		uwath					;Wait for ATN high
		ucldl					;Drive CLK/DAT
		jmp	$$bigcycle
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
