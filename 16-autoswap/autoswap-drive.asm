;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.28.+ by BSZ
;---	Handle Disk Images, AutoSwap, drive side
;---	©2023.03.18. Bin to dec conversion modification
;---	©2024.01.17. Image number check
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
;drivecode_sptr		=	drivecode_start + $100

channelno		=	2

;------------------------------------------------------------------------------
	ORG	drivecode_start
		BYT	[16]0				;Stack location
stack_top
drivecode_go
		ucldl					;CLK + DAT to Low, BUSY
		ldsph	hi(stack_top-1)			;Set SPH
		ldx	#lo(stack_top-1)
		txs					;Set SP

		jsr	clrautoswap			;Clear autoswap list file
		jsr	store_result			;"DS" store
		ldx	#2
		break	vcpu_syscall_changedisk		;CD any testdisk, expected result is an error
		jsr	store_result			;"DS" store (error value)
		txa
		jsr	store_result			;Swaplist lineno store

		jsr	setautoswap			;Select "AUTOSWAP.LST" file
		jsr	store_result			;"DS" store

		ldx	#0
		break	vcpu_syscall_changedisk		;CD TestDisk #1
		jsr	store_result			;"DS" store
		bne	$$error
		txa
		jsr	store_result			;Swaplist lineno store
		jsr	openchannel
		bne	$$error

		lda	#0				;File #1
		jsr	getstartblock			;Get file's start Tr:Sec
		bne	$$error
		jsr	readfileandcchk			;Read file & calc checksum
		bne	$$error

		usdth					;DAT = HighZ
		lda	#1				;File #2
		jsr	getstartblock			;Get file's start Tr:Sec
		bne	$$error
		jsr	readfileandcchk			;Read file & calc checksum
		bne	$$error

		usdtl					;DAT = Low
		lda	#2				;File #3
		jsr	getstartblock			;Get file's start Tr:Sec
		bne	$$error
		jsr	readfileandcchk			;Read file & calc checksum
		bne	$$error

		ldx	#1
		break	vcpu_syscall_changedisk		;CD TestDisk #2
		jsr	store_result			;"DS" store
		bne	$$error
		txa
		jsr	store_result			;Swaplist lineno store
		jsr	openchannel
		bne	$$error

		usdth					;DAT = HighZ
		lda	#3				;File #4
		jsr	getstartblock			;Get file's start Tr:Sec
		bne	$$error
		jsr	readfileandcchk			;Read file & calc checksum
		bne	$$error

		usdtl					;DAT = Low
		lda	#4				;File #5
		jsr	getstartblock			;Get file's start Tr:Sec
		bne	$$error
		jsr	readfileandcchk			;Read file & calc checksum
		bne	$$error

		usdth					;DAT = HighZ
		lda	#5				;File #6
		jsr	getstartblock			;Get file's start Tr:Sec
		bne	$$error
		jsr	readfileandcchk			;Read file & calc checksum
		bne	$$error

		ldx	#100
		break	vcpu_syscall_changedisk		;CD TestDisk #100 <- invalid, save results
		jsr	store_result			;"DS" store
		txa
		jsr	store_result			;Actual Swaplist lineno store

		jsr	changedir_parnt			;CD ..
		jsr	store_result			;"DS" store
		;bne	$$error

$$error		ldx	#$00
$$errorcopy	lda	_results,x
		sta	vcpu_errorbuffer,x
		inx
		cpx	_resultlength
		bne	$$errorcopy
		break	vcpu_syscall_exit_fillederror		;Exit, error channel's content ready

;---	Clear AUTOSWAP file:
clrautoswap	ldzph	hi(_setswpflcmd)
		ldy	#lo(_setswpflcmd)
		ldx	#_clrswpflcmd_e - _setswpflcmd
		break	vcpu_syscall_directcommand_mem		;XS without parameter
		rts

;---	Set AUTOSWAP file:
setautoswap	ldzph	hi(_setswpflcmd)
		ldy	#lo(_setswpflcmd)
		ldx	#_setswpflcmd_e - _setswpflcmd
		break	vcpu_syscall_directcommand_mem		;XS:...
		rts

_setswpflcmd	BYT	"XS"
_clrswpflcmd_e
		BYT	":AUTOSWAP.LST"
_setswpflcmd_e

;---	Change directory to parent:
changedir_parnt	ldzph	hi(_changedsk_bk)
		ldy	#lo(_changedsk_bk)
		ldx	#_changedsk_bk_e - _changedsk_bk
		break	vcpu_syscall_directcommand_mem		;CD ..
		rts
_changedsk_bk	BYT	"CD:_"
_changedsk_bk_e
;------------------------------------------------------------------------------
;---	Channel open for disk block read:
openchannel	ldzph	hi($$openchn)
		ldy	#lo($$openchn)
		ldx	#$$openchn_e - $$openchn	;"#", one character
		lda	#channelno			;Channel
		break	vcpu_syscall_open_mem
		sty	_channeladdrhi
		jmp	store_result			;Channel open "DS" store

$$openchn	BYT	"#"
$$openchn_e
;------------------------------------------------------------------------------
;---	Get file's starting block Tr:Sec
;---	A <- File No
getstartblock	jsr	store_result			;Store File No
		asl	a
		asl	a
		asl	a
		asl	a
		asl	a				;×32, 32 BYTE = one file descriptor
		sta	$$offset+1
		lda	#18				;Track
		ldx	#1				;Sector (18:1 <= first directory block)
		jsr	readsector
		bne	$$error
		ldy	_channeladdrhi
		tyzph
$$offset	ldx	#$00
		lda	$03,x				;File start Tr
		sta	_track
		jsr	store_result			;Store Track
		lda	$04,x				;File start Sec
		sta	_sector
		jsr	store_result			;Store Sector
		lda	#$00				;OK
		sta	_filelength+0
		sta	_filelength+1			;File length = 0
		sta	_filechksum+0
		sta	_filechksum+1
		sta	_filechksum+2			;File ChkSum = 0
$$error		rts
;------------------------------------------------------------------------------
;---	Read file and calculate checksum

readfileandcchk	lda	_track
		ldx	_sector
		jsr	readsector			;Read next sector from file
		bne	$$error

		ldy	_channeladdrhi
		tyzph
		lda	#254				;Number of bytes
		ldx	$00				;Next Track
		bne	$$nolastsector
		ldx	$01				;Last sector, get last used BYTE offset
		dex					;Number of bytes of last sector
		txa
$$nolastsector	pha
		clc
		adc	_filelength+0
		sta	_filelength+0
		bcc	$$ncy1
		inc	_filelength+1
$$ncy1		pla
		tay
		ldx	#0
$$chksumcalc	lda	$02,x
		clc
		adc	_filechksum+0
		sta	_filechksum+0
		bcc	$$nextbyte
		inc	_filechksum+1
		bne	$$nextbyte
		inc	_filechksum+2
$$nextbyte	inx
		dey
		bne	$$chksumcalc

		lda	$01
		sta	_sector
		lda	$00
		sta	_track				;Set next Tr:Sec
		bne	readfileandcchk			;Read next sector
		php
		jsr	copydata
		plp
$$error		rts
;------------------------------------------------------------------------------
;---	Read one sector
;---	A <- Tr
;---	X <- Sec

readsector	stx	vcpu_bin2ascii			;Convert "Sec" to ASCII string
		ldx	vcpu_bin2resultm		;Read "Middle" digit in ASCII char
		stx	$$blrdstr_sc+0
		ldx	vcpu_bin2resultl		;Read "Low" digit in ASCII char
		stx	$$blrdstr_sc+1
		sta	vcpu_bin2ascii			;Convert "Tr" to ASCII string
		lda	vcpu_bin2resultm		;Read "Middle" digit in ASCII char
		sta	$$blrdstr_tr+0
		lda	vcpu_bin2resultl		;Read "Low" digit in ASCII char
		sta	$$blrdstr_tr+1

		ldzph	hi($$blrdstr)
		ldy	#lo($$blrdstr)
		ldx	#$$blrdstr_e - $$blrdstr
		break	vcpu_syscall_directcommand_mem	;Read sector
		jmp	store_result_if_nook

$$blrdstr	BYT	"U1 "			;Command: Read block
		BYT	$30+channelno		;Channel no
		BYT	" 0 "			;Disk
$$blrdstr_tr	BYT	"00 "			;Track
$$blrdstr_sc	BYT	"00"			;Sector
$$blrdstr_e
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;---	Move length + chksum to result:
copydata	ldx	#0
$$copy		lda	_filedata,x
		jsr	store_result
		inx
		cpx	#_filedata_e - _filedata
		bne	$$copy
		rts
;------------------------------------------------------------------------------
;---	Store BYTE to result:
;---	A <- BYTE
store_result_if_nook

		cmp	#$00
		bne	store_result
		rts

store_result	stx	$$x_restore+1
		ldx	_resultlength
		sta	_results,x
		inx
		stx	_resultlength
$$x_restore	ldx	#$00			;Restore X
		cmp	#$00			;0? (If stored BYTE is "DS" code, compare "00, OK,00,00")
$$end		rts
;------------------------------------------------------------------------------
_channeladdrhi	BYT	0
_track		BYT	0
_sector		BYT	0

_filedata
_filelength	ADR	0
_filechksum	BYT	0,0,0
_filedata_e

_resultlength	BYT	0
_results
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_go
;------------------------------------------------------------------------------
