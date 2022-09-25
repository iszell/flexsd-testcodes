;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.04.+ by BSZ
;---	Send/Receive test, 1bit, drive side
;---	UDTTA/UATDT commands on drive side, reversed bit order,
;---				 preferred communication method
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
		jsr	receive_byte			;Get BYTE
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		ldx	#$00
$$recvcyc	jsr	receive_byte			;Get BYTE
		sta	lo(_drive_databuffer),x		;Save to buffer
		uindb	$$recvcyc			;X+, Y-, jump back
$$sendcyc	lda	lo(_drive_databuffer),x		;Load from buffer
		jsr	send_byte			;Put BYTE
		uindb	$$sendcyc			;X+, Y-, jump back
		uwckh					;Wait for CLK HIGH
		usdtl					;Drive DAT
		jmp	$$bigcycle

;	Receive BYTE from host:
receive_byte	uchdh					;CLK+DAT = HighZ
		uwckl					;Wait for CLK Low
		udtta	%10000000			;Read B7
		uwckh					;Wait for CLK High
		udtta	%01000000			;Read B6
		uwckl					;Wait for CLK Low
		udtta	%00100000			;Read B5
		uwckh					;Wait for CLK High
		udtta	%00010000			;Read B4
		uwckl					;Wait for CLK Low
		udtta	%00001000			;Read B2
		uwckh					;Wait for CLK High
		udtta	%00000100			;Read B2
		uwckl					;Wait for CLK Low
		udtta	%00000010			;Read B1
		uwckh					;Wait for CLK High
		udtta	%00000001			;Read B0
		rts

;	Send BYTE to host:
send_byte	uwckh					;Wait for CLK High
		uatdt	%10000000			;Put B7 to DAT
		uwckl					;Wait for CLK Low
		uatdt	%01000000			;Put B6 to DAT
		uwckh					;Wait for CLK High
		uatdt	%00100000			;Put B5 to DAT
		uwckl					;Wait for CLK Low
		uatdt	%00010000			;Put B4 to DAT
		uwckh					;Wait for CLK High
		uatdt	%00001000			;Put B3 to DAT
		uwckl					;Wait for CLK Low
		uatdt	%00000100			;Put B2 to DAT
		uwckh					;Wait for CLK High
		uatdt	%00000010			;Put B1 to DAT
		uwckl					;Wait for CLK Low
		uatdt	%00000001			;Put B0 to DAT
		rts
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
