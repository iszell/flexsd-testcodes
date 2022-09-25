;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Receive time test, 2bit, drive side
;---	USND2 command on drive side, preferred communication method
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

		break	vcpu_syscall_disableatnirq	;Disable ATN IRQ

$$bigcycle	ldx	#0
$$gendata	txa
		sta	$00,x
		inx
		bne	$$gendata
$$bigcycle2	urcv2					;Get BYTE
		ucldl					;Drive CLK/DAT
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		tay					;x BYTE
		ldx	$$datastart
		lda	$$datastart
		and	#%11110000
		ora	#%00001101			;DAT=Lo, CLK=Hi
		usnd2					;Send BYTE
$$sendcyc	lda	$00,x
		usnd2					;Send BYTE
		uindb	$$sendcyc
		uwath					;Wait for ATN High
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
