;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.08.28.+ by BSZ
;---	Read/Wirte 40 track Disk Images, AutoSwap, drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
;drivecode_sptr		=	drivecode_start + $100

channelno		=	2
;------------------------------------------------------------------------------
;	Host synchronize macro
hostsyn	MACRO
		ucldh			;CLK Lo, DAT HiZ
		uwdtl			;Wait fow DAT Lo
		uwdth			;Wait for DAT Hi
	ENDM
;------------------------------------------------------------------------------
	ORG	drivecode_start
		BYT	[16]0			;Stack location
stack_top

drivecode_init
		hostsyn					;Wait host
		ldsph	hi(stack_top-1)			;Set SPH
		ldx	#lo(stack_top-1)
		txs					;Set SP

		jsr	datainit

		jsr	setautoswap			;Select "AUTOSWAP.LST" file, "DS" store
		bne	$$error
		ldx	#imageno
		break	vcpu_syscall_changedisk		;Select test disk image
		jsr	store_result			;"DS" store
		bne	$$error
		txa
		jsr	store_result			;store swapfile lineno
		jsr	openchannel			;Open channel for direct sector r/w, "DS" store
		;bne	$$error
$$error		jmp	sendresult_exit

drivecode_onetrack
		hostsyn					;Wait host
		ldx	#0
		stx	_resultlength			;Init pointer

		lda	_track
		jsr	store_result			;TrackNo store

$$nextsector	jsr	settracksector			;Set Track+Sector
		lda	#'1'				;U1: Read Sector
		jsr	commexec
		cmp	#$00				;OK?
		beq	$$readokay
		pha
		eor	#%10000000
		jsr	store_result			;Error code store
		pla
		jsr	store_result			;Error code store
		lda	#$00
		jsr	store_result			;Error code store
		jsr	store_result			;Error code store
		jmp	$$nextblock
$$readokay	ldy	_channeladdrhi
		tyzph
		ldx	#0
$$datacopy	lda	$fc,x				;Data from readed block
		jsr	store_result			;store to result
		inx
		cpx	#4
		bne	$$datacopy

		lda	_track
		sta	$fc+0
		lda	_sector
		sta	$fc+1
		lda	_lba+0
		sta	$fc+2
		lda	_lba+1
		sta	$fc+3				;Update Track/Sector/LBA data in block
		lda	#'2'				;U2: Write Sector
		jsr	commexec			;Write back the sector

$$nextblock	inc	_lba+0
		bne	$$ncy
		inc	_lba+1				;Count next block's LBA
$$ncy		inc	_sector
		ldx	_track
		lda	_sector
		cmp	maxsectors,x
		bne	$$nextsector
		lda	#0
		sta	_sector
		inc	_track
		jmp	sendresult_exit

drivecode_goback
		hostsyn					;Wait host
		ldx	#0
		stx	_resultlength			;Init pointer
		jsr	changedir_parnt			;CD .. Go parent directory (close all buffers by design)
		jmp	sendresult_exit
;------------------------------------------------------------------------------
;---	Set AUTOSWAP file:
setautoswap	ldzph	hi($$setswpflcmd)
		ldy	#lo($$setswpflcmd)
		ldx	#$$setswpflcmd_e - $$setswpflcmd
		break	vcpu_syscall_directcommand_mem	;XS:...
		jmp	store_result			;"DS" store
$$setswpflcmd	BYT	"XS:AUTOSWAP.LST"
$$setswpflcmd_e

;---	Change directory to parent:
changedir_parnt	ldx	#$ff				;Last "image" from autoswap file
		break	vcpu_syscall_changedisk		;Select "parent" "disk image" (directory)
		jsr	store_result			;"DS" store
		txa
		jmp	store_result			;lineno store
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
;---	Set Track + Sector values / command string:
settracksector	lda	_track
		sta	vcpu_bin2ascii			;Convert "Tr" to ASCII string
		lda	vcpu_bin2resultm		;Read "Middle" digit in ASCII char
		sta	commandstr_tr+0
		lda	vcpu_bin2resultl		;Read "Low" digit in ASCII char
		sta	commandstr_tr+1
		lda	_sector
		sta	vcpu_bin2ascii			;Convert "Sec" to ASCII string
		lda	vcpu_bin2resultm		;Read "Middle" digit in ASCII char
		sta	commandstr_sc+0
		lda	vcpu_bin2resultl		;Read "Low" digit in ASCII char
		sta	commandstr_sc+1
		rts
;------------------------------------------------------------------------------
;---	Command execute:
;---	A <- '1' / '2': U1 / U2: Sector Read / Write
commexec	sta	commandstr_12
		ldzph	hi(commandstr)
		ldy	#lo(commandstr)
		ldx	#commandstr_e - commandstr
		break	vcpu_syscall_directcommand_mem	;Read sector
		rts
;------------------------------------------------------------------------------
;---	Store BYTE to result:
;---	A <- BYTE
store_result	stx	$$x_restore+1
		ldx	_resultlength
		sta	_results,x
		inx
		stx	_resultlength
$$x_restore	ldx	#$00			;Restore X
		cmp	#$00			;0? (If stored BYTE is "DS" code, compare "00, OK,00,00")
$$end		rts
;------------------------------------------------------------------------------
;---	Copy result to error buffer and exit:
sendresult_exit	ldx	#0
$$copy		lda	_results,x
		sta	vcpu_errorbuffer,x
		inx
		cpx	_resultlength
		bne	$$copy
		break	vcpu_syscall_exit_fillederror
;------------------------------------------------------------------------------
;---	Init:
datainit	ldx	#0
		stx	_resultlength			;Init pointer
		stx	_sector
		stx	_lba+1
		inx
		stx	_track				;Start Track:Sector = 01:00
		stx	_lba+0				;Start LBA = $0001
		rts
;------------------------------------------------------------------------------
commandstr	BYT	"U"
commandstr_12	BYT	"? "			;Command: U1/U2: Read/Write block
		BYT	$30+channelno		;Channel no
		BYT	" 0 "			;Disk
commandstr_tr	BYT	"00 "			;Track
commandstr_sc	BYT	"00"			;Sector
commandstr_e
;------------------------------------------------------------------------------
;---	Open image file in raw mode:
drivecode_openfile
		hostsyn					;Wait host

		ldsph	hi(stack_top-1)			;Set SPH
		ldx	#lo(stack_top-1)
		txs					;Set SP

		jsr	datainit			;Init

		ldx	#0				;Start offset: 0
		ldy	#lo(256)			;Number of requested bytes: 256
		break	vcpu_syscall_setfatparams
		ldzph	hi($$imagename)
		ldy	#lo($$imagename)
		ldx	#$$imagename_e - $$imagename	;Image file name
		lda	#channelno			;Channel
		break	vcpu_syscall_open_mem
		sty	_channeladdrhi
		jsr	store_result			;Channel open "DS" store
		jmp	sendresult_exit
$$imagename	BYT	"VCPUTST40TRK*,R"		;Disk image file name
$$imagename_e
;------------------------------------------------------------------------------
;---	Read sector datas / one track from file:
drivecode_onetrkfromfile
		hostsyn					;Wait host
		ldx	#0				;Start offset: 0
		stx	_resultlength			;Init pointer
		ldy	#lo(256)			;Number of requested bytes: 256
		break	vcpu_syscall_setfatparams

		lda	_track
		jsr	store_result			;TrackNo store

$$nextsector	ldy	_channeladdrhi
		tyzph
		ldx	#0
$$datacopy	lda	$fc,x				;Data from readed block
		jsr	store_result			;store to result
		inx
		cpx	#4
		bne	$$datacopy

		lda	vcpu_param_eoi			;End of file?
		bne	$$endoffile
		lda	#channelno			;A: Channel
		break	vcpu_syscall_refillbuffer	;Read next bytes from file
		;cpy	#$ff				;ERROR?
		;beq	$$fileerror			;If ERROR, ...

$$endoffile	inc	_lba+0
		bne	$$ncy
		inc	_lba+1				;Count next block's LBA
$$ncy		inc	_sector
		ldx	_track
		lda	_sector
		cmp	maxsectors,x
		bne	$$nextsector
		lda	#0
		sta	_sector
		inc	_track
		jmp	sendresult_exit
;$$fileerror
;------------------------------------------------------------------------------
;---	Close image file:
drivecode_closefile
		hostsyn					;Wait host
		ldx	#0
		stx	_resultlength			;Init pointer
		lda	#channelno			;A: Channel
		break	vcpu_syscall_close		;Close file
		jsr	store_result			;Channel open "DS" store
		jmp	sendresult_exit
;------------------------------------------------------------------------------
maxsectors
	INCLUDE	"maxsectors.asm"		;Sectors / track table
;------------------------------------------------------------------------------
_channeladdrhi	BYT	0
_lba		ADR	0
_track		BYT	0
_sector		BYT	0

_resultlength	BYT	0
_results
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	drivecode_init
	SHARED	drivecode_onetrack
	SHARED	drivecode_goback
	SHARED	drivecode_openfile
	SHARED	drivecode_onetrkfromfile
	SHARED	drivecode_closefile
;------------------------------------------------------------------------------
