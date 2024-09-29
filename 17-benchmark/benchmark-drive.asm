;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.10.10.+ by BSZ
;---	File Load benchmark, drive side
;---	240325+: Testfile changed
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
;---	Actual testfile
	INCLUDE	"../common/len_chks.asm"
megafile_name	=	meg1file_name
megafile_length	=	meg1file_length
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $100
drivecode_sptr		=	drivecode_start + $000

channelno		=	2
seekpos			=	(megafile_length)-256	;x MB file last block start position
;------------------------------------------------------------------------------
	ORG	drivecode_start

;---	Read time test:
drivecode_read	ucldl					;Drive CLK/DAT
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
		lda	_modebits
		eor	#%01000000			;Swap 254/256 mode automatically
		sta	_modebits
		udely	$ff				;Wait a bit
		usckh					;CLK = HighZ
		usdth					;DAT = HighZ
		break	vcpu_syscall_exit_ok
;------------------------------------------------------------------------------
;---	Seek time test:
drivecode_seek	uchdh					;Release CLK/DAT lines
		ldx	#_filename_end-_filename
		ldzph	hi(_filename)
		ldy	#lo(_filename)
		lda	#channelno			;X: Filename Length, A: Channel, ZPH:Y: Address of file name
		break	vcpu_syscall_open_mem		;File Open
		cpy	#$ff				;ERROR?
		beq	error
		usdtl					;Set DAT to low
		uwckl					;Wait for CLK low
		uwckh					;Wait for CLK High

		ldx	#2				;Start offset: 2
		ldy	#lo(254)			;Number of requested bytes: 254 (Default settings)
		break	vcpu_syscall_setfatparams
		jsr	seekinfile
		jsr	channelinfo
		ldx	#0
		jsr	savechannelprms			;Save params / default block settings
		ldx	#0				;Start offset: 0
		ldy	#lo(256)			;Number of requested bytes: 256
		break	vcpu_syscall_setfatparams
		jsr	seekinfile
		jsr	channelinfo
		ldx	#3
		jsr	savechannelprms			;Save params / modified block settings
		usdth					;Release DAT line, ready
		lda	#channelno			;A: Channel
		break	vcpu_syscall_close		;Close file
		break	vcpu_syscall_exit_ok

;	ERROR:
error		break	vcpu_syscall_exit_remain

;---	Seek:
seekinfile	ldzph	hi(_seekstr)
		ldy	#lo(_seekstr)
		ldx	#_seekstr_end-_seekstr
		break	vcpu_syscall_directcommand_mem	;Seek
		cmp	#$00				;OK?
		bne	error				;If any error, exit (Return address remain in stack, no problem)
		rts
;---	Get channel parameters:
channelinfo	lda	#channelno			;A: Channel
		break	vcpu_syscall_getchannelparams	;Get channel parameters
		cpy	#$ff				;Any error?
		beq	error				;If any error, exit (Return address remain in stack, no problem)
		rts
;---	Save channel parameters for later verification:
savechannelprms	lda	vcpu_param_position
		sta	drv_chnlparsave+0,x
		lda	vcpu_param_lastused
		sta	drv_chnlparsave+1,x
		lda	vcpu_param_eoi
		sta	drv_chnlparsave+2,x
		rts
;------------------------------------------------------------------------------
_modebits	BYT	%00000000			;Mode bits (B6=0: 254, =1: 256 BYTEs / block)
_filename	BYT	megafile_name,"*,R"
_filename_end
_seekstr	BYT	"P"
_seekchno	BYT	channelno
_seekpos	BYT	(seekpos & $ff)
		BYT	((seekpos >> 8) & $ff)
		BYT	((seekpos >> 16) & $ff)
		BYT	((seekpos >> 24) & $ff)
_seekstr_end
drv_chnlparsave	BYT	0,0,0
		BYT	0,0,0
drv_chnlparsave_size = * - drv_chnlparsave
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_read
	SHARED	drivecode_seek
	SHARED	drv_chnlparsave
	SHARED	drv_chnlparsave_size
;------------------------------------------------------------------------------
