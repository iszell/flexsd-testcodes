;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.10.10.+ by BSZ
;---	File Load benchmark, drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
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
		udely	$ff				;Wait a bit

$$filecyc	lda	vcpu_clkdatout
		eor	#%00000010			;Toggle DAT
		sta	vcpu_clkdatout
		lda	vcpu_param_eoi			;End of file?
		bne	$$endoffile
		lda	#channelno			;A: Channel
		break	vcpu_syscall_refillbuffer	;Read next bytes from file
		cpy	#$ff				;ERROR?
		bne	$$filecyc			;If OK, send next block

;	ERROR:
$$error		break	vcpu_syscall_exit_remain

;	END of FILE:
$$endoffile	lda	#channelno			;A: Channel
		break	vcpu_syscall_close		;Close file
		udely	$ff				;Wait a bit
		usckh					;CLK = HighZ
		usdth					;DAT = HighZ
		break	vcpu_syscall_exit_ok
;------------------------------------------------------------------------------
_filename	BYT	"TSTDAT2M*,R"
_filename_end
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_go
;------------------------------------------------------------------------------
