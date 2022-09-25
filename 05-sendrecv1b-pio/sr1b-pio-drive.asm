;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.07.19.+ by BSZ
;---	Send/Receive test, 1bit, drive side
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

$$bigcycle	lda	#%00000011
		sta	vcpu_clkdatout			;Release CLK/DAT
		jsr	getbyte
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
getbyte
$$waitcl1	bit	vcpu_clkio
		bmi	$$waitcl1			;Wait for CLK LOW
		lda	vcpu_datio			;Read B0
		lsr	a
$$waitch1	bit	vcpu_clkio
		bpl	$$waitch1			;Wait for CLK HIGH
		ora	vcpu_datio			;Read B1
		lsr	a
$$waitcl2	bit	vcpu_clkio
		bmi	$$waitcl2			;Wait for CLK LOW
		ora	vcpu_datio			;Read B2
		lsr	a
$$waitch2	bit	vcpu_clkio
		bpl	$$waitch2			;Wait for CLK HIGH
		ora	vcpu_datio			;Read B3
		lsr	a
$$waitcl3	bit	vcpu_clkio
		bmi	$$waitcl3			;Wait for CLK LOW
		ora	vcpu_datio			;Read B4
		lsr	a
$$waitch3	bit	vcpu_clkio
		bpl	$$waitch3			;Wait for CLK HIGH
		ora	vcpu_datio			;Read B5
		lsr	a
$$waitcl4	bit	vcpu_clkio
		bmi	$$waitcl4			;Wait for CLK LOW
		ora	vcpu_datio			;Read B6
		lsr	a
$$waitch4	bit	vcpu_clkio
		bpl	$$waitch4			;Wait for CLK HIGH
		ora	vcpu_datio			;Read B7
		rts

;---	Send BYTE to computer:
putbyte		sta	vcpu_datio			;Set B0
		lsr	a
$$waitscl1	bit	vcpu_clkio
		bmi	$$waitscl1			;Wait for CLK LOW
		sta	vcpu_datio			;Set B1
		lsr	a
$$waitsch1	bit	vcpu_clkio
		bpl	$$waitsch1			;Wait for CLK HIGH
		sta	vcpu_datio			;Set B2
		lsr	a
$$waitscl2	bit	vcpu_clkio
		bmi	$$waitscl2			;Wait for CLK LOW
		sta	vcpu_datio			;Set B3
		lsr	a
$$waitsch2	bit	vcpu_clkio
		bpl	$$waitsch2			;Wait for CLK HIGH
		sta	vcpu_datio			;Set B4
		lsr	a
$$waitscl3	bit	vcpu_clkio
		bmi	$$waitscl3			;Wait for CLK LOW
		sta	vcpu_datio			;Set B5
		lsr	a
$$waitsch3	bit	vcpu_clkio
		bpl	$$waitsch3			;Wait for CLK HIGH
		sta	vcpu_datio			;Set B6
		lsr	a
$$waitscl4	bit	vcpu_clkio
		bmi	$$waitscl4			;Wait for CLK LOW
		sta	vcpu_datio			;Set B7
$$waitsch4	bit	vcpu_clkio
		bpl	$$waitsch4			;Wait for CLK HIGH
		rts
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
;------------------------------------------------------------------------------
