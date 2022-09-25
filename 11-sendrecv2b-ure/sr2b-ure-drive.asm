;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Send/Receive test, 2bit, drive side
;---	UCDTA/UATCD commands on drive side, reversed bit order,
;---				 preferred communication method
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
		jsr	getbyte				;Get BYTE
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		ldx	#$00
$$recvcyc	jsr	getbyte				;Get BYTE
		sta	lo(_drive_databuffer),x		;Save to buffer
		uindb	$$recvcyc			;X+, Y-, jump back
$$sendcyc	lda	lo(_drive_databuffer),x		;Load from buffer
		uwath					;Wait for ATN high
		uatcd	%01000000, %10000000		;B6 -> CLK, B7 -> DAT
		uwatl					;Wait ATN Low
		uatcd	%00010000, %00100000		;B4 -> CLK, B5 -> DAT
		uwath					;Wait ATN High
		uatcd	%00000100, %00001000		;B2 -> CLK, B3 -> DAT
		uwatl					;Wait ATN Low
		uatcd	%00000001, %00000010		;B0 -> CLK, B1 -> DAT
		uindb	$$sendcyc			;X+, Y-, jump back
		uwath					;Wait for ATN high
		ucldl					;Drive CLK/DAT
		jmp	$$bigcycle
;------------------------------------------------------------------------------
;---	Get BYTE:
getbyte		uchdh					;Release CLK/DAT
		uwatl					;Wait ATN Low
		ucdta	%01000000, %10000000		;CLK -> B6, DAT -> B7
		uwath					;Wait ATN High
		ucdta	%00010000, %00100000		;CLK -> B4, DAT -> B5
		uwatl					;Wait ATN Low
		ucdta	%00000100, %00001000		;CLK -> B2, DAT -> B3
		uwath					;Wait ATN High
		ucdta	%00000001, %00000010		;CLK -> B0, DAT -> B1
		rts
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
