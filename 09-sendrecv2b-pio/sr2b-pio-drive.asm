;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.07.+ by BSZ
;---	Send/Receive test, 2bit, drive side
;---	Programmed I/O on drive side, only for testing, not recommended for
;---	  regular use!
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
drivecode_sptr		=	drivecode_start + $000
;------------------------------------------------------------------------------
	ORG	drivecode_start

		lda	#%00000000
		sta	vcpu_datio			;Drive DAT

		ldzph	hi(drivecode_zptr)		;Set ZPH
		ldsph	hi(drivecode_sptr)		;Set SPH
		ldx	#$ff
		txs					;Set SP

		break	vcpu_syscall_disableatnirq	;Disable ATN IRQ

$$bigcycle	jsr	getbyte
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		ldy	#$00
$$recvcyc	jsr	getbyte
		sta	_drive_databuffer,y
		iny
		bne	$$recvcyc
$$sendcyc	lda	_drive_databuffer,y
		jsr	putbyte
		iny
		bne	$$sendcyc
		lda	#%00000000
		sta	vcpu_clkdatout			;Drive CLK/DAT
		jmp	$$bigcycle

;---	Get BYTE from computer:
getbyte		lda	#%00000011
		sta	vcpu_clkdatout			;Release CLK/DAT
$$waital1	bit	vcpu_atnsrqin
		bmi	$$waital1			;Wait for ATN Low
		lda	vcpu_clkdatin			;Read B10
		lsr	a
		lsr	a
$$waitah1	bit	vcpu_atnsrqin
		bpl	$$waitah1			;Wait for ATN High
		ora	vcpu_clkdatin			;Read B32
		lsr	a
		lsr	a
$$waital2	bit	vcpu_atnsrqin
		bmi	$$waital2			;Wait for ATN Low
		ora	vcpu_clkdatin			;Read B54
		lsr	a
		lsr	a
$$waitah2	bit	vcpu_atnsrqin
		bpl	$$waitah2			;Wait for ATN High
		ora	vcpu_clkdatin			;Read B76
		rts

;---	Send BYTE to computer:
putbyte		sta	vcpu_clkdatout			;Set B10
		lsr	a
		lsr	a
$$waitsal1	bit	vcpu_atnsrqin
		bmi	$$waitsal1			;Wait for ATN Low
		sta	vcpu_clkdatout			;Set B32
		lsr	a
		lsr	a
$$waitsah1	bit	vcpu_atnsrqin
		bpl	$$waitsah1			;Wait for ATN High
		sta	vcpu_clkdatout			;Set B54
		lsr	a
		lsr	a
$$waitsal2	bit	vcpu_atnsrqin
		bmi	$$waitsal2			;Wait for ATN Low
		sta	vcpu_clkdatout			;Set B76
$$waitsah2	bit	vcpu_atnsrqin
		bpl	$$waitsah2			;Wait for ATN High
		rts
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
