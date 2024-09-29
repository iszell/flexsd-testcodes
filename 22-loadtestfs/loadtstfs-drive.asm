;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.10.17.+ by BSZ
;---	File Load test, C128, Fast Serial, drive side
;---	FSTXB command on drive side
;---	240325+: Testfile changed
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
;drivecode_zptr		=	drivecode_start + $100
def_linkchk_byte	=	$50

channelno		=	2
;------------------------------------------------------------------------------
	ORG	drivecode_start
_modebits	BYT	%00000000			;Previously setted mode bits

_stack		BYT	0,0,0,0,0,0,0,0			;Stack
_stack_end

;	Fast Serial link check:
drivecode_fsc	ldx	#lo(fssender)
		ldy	#hi(fssender)
		tyxu1				;Ser USER1 vector to fast serial send routine

		fsrds				;Fast serial Receive disable (receive not needed for this test)
		ucldh				;Set CLK to Low / DAT to HiZ
		uwdtl				;Wait DAT to Low
		uwdth				;Wait DAT to High
		lda	#def_linkchk_byte	;Link test data
		user1				;Send
		uchdh				;Release CLK+DAT (FSTXB maybe leaved low), ready
		break	vcpu_syscall_exit_ok

;---	Fast Serial send:
fssender	fstxb				;Send data to host in Fast Serial
		userr				;return form USERx

;	Load file:
drivecode_ld	ucldh					;Drive CLK, release DAT
		;ldzph	hi(drivecode_zptr)
		ldsph	hi(_stack_end-1)
		ldx	#lo(_stack_end-1)
		txs

		fsrds				;Fast serial Receive disable (receive not needed for this test)

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
		user1					;Send
		usckh					;Release CLK, new data sended to host
		tya					;BYTEno
		uwckl					;Wait to CLK low
		user1					;Send

$$sendcyc	lda	$00,x				;Read BYTE from buffer
		uwckh
		fstxb					;Send data to host in Fast Serial
		uindb	$$sendnext
		uwckl
		uwckh
		ucldh
		jmp	$$nextblock
$$sendnext	lda	$00,x				;Read next BYTE from buffer
		uwckl
		fstxb					;Send data to host in Fast Serial
		uindb	$$sendcyc
		uwckh					;Wait for CLK High
		ucldh					;Drive CLK, BUSY

$$nextblock	lda	vcpu_param_eoi			;End of file?
		bne	$$endoffile
		lda	#channelno			;A: Channel
		break	vcpu_syscall_refillbuffer	;Read next block from file
		cpy	#$ff				;ERROR?
		bne	$$filecyc			;If OK, send next block

;	ERROR:
$$error		lda	#%00111111			;Error!
		user1					;Send
		usckh					;Release CLK
		break	vcpu_syscall_exit_remain

;	END of FILE:
$$endoffile	lda	#channelno			;A: Channel
		break	vcpu_syscall_close		;Close file
		lda	#%11001111			;File END (B10 != %00: not BUSY)
		user1					;Send
		usckh					;Release CLK
		lda	_checksum+0
		uwckl
		user1					;Send
		lda	_checksum+1
		uwckh
		user1					;Send
		lda	_checksum+2
		uwckl
		user1					;Send
		lda	_length+0
		uwckh
		user1					;Send
		lda	_length+1
		uwckl
		user1					;Send
		lda	_length+2
		uwckh
		user1					;Send
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
_filename	BYT	megafile_name,"*,R"
_filename_end
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_fsc
	SHARED	drivecode_ld
	SHARED	def_linkchk_byte
;------------------------------------------------------------------------------
