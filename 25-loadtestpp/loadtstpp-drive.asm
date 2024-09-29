;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2024.08.13.+ by BSZ
;---	File Load test, parallel port, drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
vcpu_revno = 2
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
;---	Actual testfile
	INCLUDE	"../common/len_chks.asm"
megafile_name	=	meg1file_name
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $100
def_linkchk_byte1	=	$5a
def_linkchk_byte2	=	$a5

channelno		=	2
;------------------------------------------------------------------------------
	ORG	drivecode_start
_modebits	BYT	%00000000			;Previously setted mode bits

_stack		BYT	0,0,0,0,0,0,0,0			;Stack
_stack_end

;	Parallel link check:
drivecode_ppc	;ldzph	hi(drivecode_zptr)
		ldsph	hi(_stack_end-1)
		ldx	#lo(_stack_end-1)
		txs

		lda	#%11111111
		ppdwr				;Release PP lines
		lda	#def_linkchk_byte1	;$5A
		ucldh				;Set CLK to Low / DAT to HiZ
		uwdtl				;Wait for DAT low
		ppdwr				;Write data to PP
		ppack				;1µSec pulse on DRWP line
		lda	#def_linkchk_byte2	;$A5
		ppwai				;Wait previous data accept
		ppdwr				;Write data to PP
		ppack				;1µSec pulse on DRWP line
		lda	#%11111111		;$FF
		ppwai				;Wait previous data accept
		ppdwr				;Release parallel lines
		uchdh				;Release CLK+DAT lines
		uwdth				;Wait for DAT high
		break	vcpu_syscall_exit_ok

;	Load file:
drivecode_ld	ucldh					;Drive CLK, release DAT
		uwdtl
		uwdth					;Wait H-to-L-to-H pulse in DAT line
		ucldl					;Drive CLK/DAT, BUSY

		ldzph	hi(drivecode_zptr)

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

		ldx	#_filename_end-_filename
		ldzph	hi(_filename)
		ldy	#lo(_filename)
		lda	#channelno			;X: Filename Length, A: Channel, ZPH:Y: Address of file name
		break	vcpu_syscall_open_mem		;File Open
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
		ppdwr					;Put BYTE
		ucldh					;CLK to Low, DAT to High, READY
		tya					;BYTEno
		ppwai					;Wait host ack
		ppdwr					;Put BYTE
$$sendcyc	lda	$00,x				;Read BYTE from buffer
		ppwai					;Wait host ack
		ppdwr					;Put BYTE
		uindb	$$sendcyc
		ppwai					;Wait host ack
		ucldl					;Drive CLK/DAT, BUSY

		lda	vcpu_param_eoi			;End of file?
		bne	$$endoffile
		lda	#channelno			;A: Channel
		break	vcpu_syscall_refillbuffer	;Read next block from file
		cpy	#$ff				;ERROR?
		bne	$$filecyc			;If OK, send next block

;	ERROR:
$$error		lda	#%00111111			;Error! (B10 != %00: not BUSY)
		ppdwr					;Put BYTE
		ucldh					;CLK to Low, DAT to High, READY
		ppwai					;Wait host ack
		break	vcpu_syscall_exit_remain

;	END of FILE:
$$endoffile	lda	#channelno			;A: Channel
		break	vcpu_syscall_close		;Close file
		lda	#%11001111			;File END (B10 != %00: not BUSY)
		ppdwr					;Put BYTE
		ucldh					;CLK to Low, DAT to High, READY
		lda	_checksum+0
		ppwai					;Wait host ack
		ppdwr					;Put BYTE
		lda	_checksum+1
		ppwai					;Wait host ack
		ppdwr					;Put BYTE
		lda	_checksum+2
		ppwai					;Wait host ack
		ppdwr					;Put BYTE
		lda	_length+0
		ppwai					;Wait host ack
		ppdwr					;Put BYTE
		lda	_length+1
		ppwai					;Wait host ack
		ppdwr					;Put BYTE
		lda	_length+2
		ppwai					;Wait host ack
		ppdwr					;Put BYTE
		ppwai					;Wait host ack

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
_filename_end
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_ppc
	SHARED	drivecode_ld
	SHARED	def_linkchk_byte1
	SHARED	def_linkchk_byte2
;------------------------------------------------------------------------------
