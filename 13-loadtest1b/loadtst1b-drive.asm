;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.12.+ by BSZ
;---	File Load test, 1bit, drive side
;---	240325+: Testfile changed
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
;---	Actual testfile
	INCLUDE	"../common/len_chks.asm"
megafile_name	=	meg1file_name
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $100
drivecode_sptr		=	drivecode_start + $000

channelno		=	2
;------------------------------------------------------------------------------
	ORG	drivecode_start
_modebits	BYT	%00000000			;Previously setted mode bits

drivecode_go	ucldl					;Drive CLK/DAT
		ldzph	hi(drivecode_zptr)
		ldsph	hi(drivecode_sptr)
		ldx	#lo(drivecode_sptr + $ff)
		txs

		lda	#0
		sta	_checksum+0
		sta	_checksum+1
		sta	_checksum+2			;CheckSum init
		sta	_length+0
		sta	_length+1
		sta	_length+2			;Length init

		ldx	#2				;Start offset: 2
		ldy	#lo(254)			;Number of requested bytes: 254
		bit	_modebits			;254 or 256 BYTEs?
		bvc	$$setfatparms
		ldx	#0				;Start offset: 0
		ldy	#lo(256)			;Number of requested bytes: 256
$$setfatparms	break	vcpu_syscall_setfatparams

		ldx	#0
$$fncopy	lda	_filename,x
		sta	vcpu_commandbuffer,x
		beq	$$fncok
		inx
		bne	$$fncopy			;BRA
$$fncok		dex
		lda	#channelno			;X: Filename Length, A: Channel
		break	vcpu_syscall_open		;File Open
		cpy	#$ff				;ERROR?
		beq	$$error
		tyzph					;Set ZPH to used block-buffer

$$filecyc	lda	vcpu_param_lastused
		sec
		sbc	vcpu_param_position
		sta	$$sendlen+1
		jsr	calclength

		bit	_modebits
		bmi	$$nocalccks
		jsr	calcchksum			;Calc CheckSum, if required
$$nocalccks

		ldx	vcpu_param_position		;X: START position
$$sendlen	ldy	#0				;Y: BYTEno (Self-modified code, $FF: 256 BYTE)
		lda	#%11110011			;New data present (B10 != %00: not BUSY)
		usnd1					;Put BYTE
		tya					;BYTEno
		usnd1					;Put BYTE
$$sendcyc	lda	$00,x				;Read BYTE from buffer
		usnd1					;Put BYTE
		uindb	$$sendcyc
		uwckh					;Wait for CLK High
		ucldl					;Drive CLK/DAT, BUSY

		lda	vcpu_param_eoi			;End of file?
		bne	$$endoffile
		lda	#channelno			;A: Channel
		break	vcpu_syscall_refillbuffer	;Read next block from file
		cpy	#$ff				;ERROR?
		bne	$$filecyc			;If OK, send next block

;	ERROR:
$$error		lda	#%00111111			;Error! (B10 != %00: not BUSY)
		usnd1					;Put BYTE
		uwckh					;Wait for CLK High
		break	vcpu_syscall_exit_remain

;	END of FILE:
$$endoffile	lda	#channelno			;A: Channel
		break	vcpu_syscall_close		;Close file
		lda	#%11001111			;File END (B10 != %00: not BUSY)
		usnd1					;Put BYTE
		lda	_checksum+0
		usnd1					;Put BYTE
		lda	_checksum+1
		usnd1					;Put BYTE
		lda	_checksum+2
		usnd1					;Put BYTE
		lda	_length+0
		usnd1					;Put BYTE
		lda	_length+1
		usnd1					;Put BYTE
		lda	_length+2
		usnd1					;Put BYTE
		uwckh					;Wait for CLK High
		break	vcpu_syscall_exit_ok
;------------------------------------------------------------------------------
;	CHKSUM calculator:
calcchksum	ldx	vcpu_param_position		;X: START position
$$calccks_c	lda	$00,x
		clc
		adc	_checksum+0
		sta	_checksum+0
		bcc	$$calccks_n
		inc	_checksum+1
		bne	$$calccks_n
		inc	_checksum+2
$$calccks_n	cpx	vcpu_param_lastused
		beq	$$calccks_e
		inx
		jmp	$$calccks_c
$$calccks_e	rts
;------------------------------------------------------------------------------
;---	Length calculator
;---	A <- ByteNo
calclength	jsr	$$addone
		clc
		adc	_length+0
		sta	_length+0
		bcc	$$ncy
		bcs	$$cy
$$addone	inc	_length+0
		bne	$$ncy
$$cy		inc	_length+1
		bne	$$ncy
		inc	_length+2
$$ncy		rts
;------------------------------------------------------------------------------
_checksum	BYT	0,0,0
_length		BYT	0,0,0
_filename	BYT	megafile_name,"*,R",0
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_go
;------------------------------------------------------------------------------
