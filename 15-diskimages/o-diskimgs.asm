;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.08.28.+ by BSZ
;---	Handle Disk Images, computer side
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"../common/len_chks.asm"
	INCLUDE	"diskimgs-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,"SD2IEC DISK IMAGES / CD:",ascii_return,0

		jsr	sd2i_scanning_bus
		sta	z_fa				;Set SD2IEC Unit No
		cmp	#0				;Any SD2IEC on the bus?
		bne	$$sd2iecpresent
		jsr	rom_primm
		BYT	ascii_return,"NO SD2IEC DETECTED",0
		jmp	$$exit
$$sd2iecpresent	jsr	rom_primm
		BYT	ascii_return,"SD2IEC UNIT NO: #",0
		lda	#0
		ldx	z_fa
		jsr	bas_linprt
		jsr	sd2i_checkvcpusupport		;Check SD2IEC VCPU support
		bcc	$$vcpuready
		jmp	$$exit
$$vcpuready	jsr	rom_primm
		BYT	ascii_return,"DOWNLOAD CODE TO DRV",0
		jsr	sd2i_writememory
		ADR	_drivecode
		ADR	_drivecode_end-_drivecode
		ADR	drivecode_start

		jsr	rom_primm
		BYT	ascii_return,"START CODE IN DRV",0
		ldx	#lo(drivecode_go)
		ldy	#hi(drivecode_go)
		jsr	sd2i_execmemory_simple

		jsr	rom_primm
		BYT	ascii_return,ascii_return,"WAIT FOR DRIVE",0

		jsr	waitdrive

		jsr	rom_primm
		BYT	"READY, RESULT:",0

		jsr	getresults		;Get results from drive

		lda	#0
		sta	_diskno
		sta	_filedatapos
		jsr	rom_primm
		BYT	ascii_return,"SELECT #1 .D64",0
		jsr	printokerror
		jsr	rom_primm
		BYT	ascii_return,"OPEN CHANNEL",0
		jsr	printokerror
		jsr	printfiledata
		jsr	printfiledata
		jsr	printfiledata

		jsr	rom_primm
		BYT	ascii_return,"CHANGE DIR BACK",0
		jsr	printokerror
		jsr	rom_primm
		BYT	ascii_return,"SELECT #2 .D64",0
		jsr	printokerror
		jsr	rom_primm
		BYT	ascii_return,"OPEN CHANNEL",0
		jsr	printokerror
		inc	_diskno
		jsr	printfiledata
		jsr	printfiledata
		jsr	printfiledata

		jsr	rom_primm
		BYT	ascii_return,"CHANGE DIR BACK",0
		jsr	printokerror

$$exit		jmp	program_exit

;---	Print OK/ERROR
printokerror	jsr	getbytefromresults
		bcs	$$error_nodata
		bne	$$error_number
		jsr	rom_primm
		BYT	" OK",0
		rts

$$error_number	jsr	rom_primm
		BYT	" ERROR ($",0
		jsr	mon_puthex
		jsr	rom_primm
		BYT	")",ascii_return,0
		pla
		pla				;Drop return address
		rts

$$error_nodata	jsr	rom_primm
		BYT	" ERROR (NO DATA)",ascii_return,0
		pla
		pla				;Drop return address
		rts

;---	Print one file data:
printfiledata	jsr	rom_primm
		BYT	ascii_return,"D",0
		lda	_diskno
		ora	#'0'
		jsr	rom_bsout
		lda	#'F'
		jsr	rom_bsout
		jsr	getbytefromresults
		bcs	$$error_nodata
		ora	#'0'
		jsr	rom_bsout
		jsr	rom_primm
		BYT	" TR:",0
		jsr	getbytefromresults
		bcs	$$error_nodata
		jsr	mon_puthex
		jsr	rom_primm
		BYT	" SEC:",0
		jsr	getbytefromresults
		bcs	$$error_nodata
		jsr	mon_puthex
		jsr	rom_primm
		BYT	" L:",0
		jsr	$$getlength
		bcs	$$error_nodata
		lda	_len+1
		jsr	mon_puthex
		lda	_len+0
		jsr	mon_puthex
		jsr	rom_primm
		BYT	" CS:",0
		jsr	$$getchecksum
		bcs	$$error_nodata
		lda	_chksum+2
		jsr	mon_puthex
		lda	_chksum+1
		jsr	mon_puthex
		lda	_chksum+0
		jsr	mon_puthex

		ldx	_filedatapos
		ldy	#0
$$filechk	lda	_filedata,y
		cmp	filedata,x
		bne	$$dataerror
		inx
		iny
		cpy	#_filedata_e - _filedata
		bne	$$filechk
		jsr	rom_primm
		BYT	" GOOD",0
		jmp	$$datagoodcont

$$error_nodata	jsr	rom_primm
		BYT	" NO DATA",ascii_return,0
		rts

$$dataerror	jsr	rom_primm
		BYT	" DIFF",0
$$datagoodcont	lda	_filedatapos
		clc
		adc	#_filedata_e - _filedata
		sta	_filedatapos
		rts

$$getlength	jsr	getbytefromresults
		sta	_len+0
		jsr	getbytefromresults
		sta	_len+1
		rts

$$getchecksum	jsr	getbytefromresults
		sta	_chksum+0
		jsr	getbytefromresults
		sta	_chksum+1
		jsr	getbytefromresults
		sta	_chksum+2
		rts

_diskno		BYT	0
_filedatapos	BYT	0

_filedata
_len		ADR	0
_chksum		BYT	0,0,0
_filedata_e


filedata	ADR	file1_length
		BYT	(file1_chks & $ff), ((file1_chks >> 8) & $ff), ((file1_chks >> 16) & $ff)
		ADR	file2_length
		BYT	(file2_chks & $ff), ((file2_chks >> 8) & $ff), ((file2_chks >> 16) & $ff)
		ADR	file3_length
		BYT	(file3_chks & $ff), ((file3_chks >> 8) & $ff), ((file3_chks >> 16) & $ff)
		ADR	file4_length
		BYT	(file4_chks & $ff), ((file4_chks >> 8) & $ff), ((file4_chks >> 16) & $ff)
		ADR	file5_length
		BYT	(file5_chks & $ff), ((file5_chks >> 8) & $ff), ((file5_chks >> 16) & $ff)
		ADR	file6_length
		BYT	(file6_chks & $ff), ((file6_chks >> 8) & $ff), ((file6_chks >> 16) & $ff)



;------------------------------------------------------------------------------
;---	Get results form drive:

getresults	lda	#0
		sta	_resultspos
		lda	#_resultsdata_e - _resultsdata
		ldx	#lo(_resultsdata)
		ldy	#hi(_resultsdata)
		jsr	sd2i_recvanswer
		sty	_resultslength
		rts

;---	Get BYTE from results:
getbytefromresults

		stx	$$x_restore+1
		ldx	_resultspos
		cpx	_resultslength
		bne	$$okay
		sec				;No data
		bcs	$$x_restore		;BRA
$$okay		lda	_resultsdata,x
		inx
		stx	_resultspos
		clc				;Data
$$x_restore	ldx	#0			;X restore
		eor	#$00			;Set Z bit, Cy not changed
		rts

_resultslength	BYT	0
_resultspos	BYT	0
;------------------------------------------------------------------------------
;---	Wait drive activity:
waitdrive	lda	#%11111111
		sta	$$state
$$waitcycle
    IF target_platform == 20
		lda	$911f			;VIA1 DRA
		and	#%00000011
		cmp	#%00000011
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	$dd00			;CIA port for handle serial lines
		and	#%11000000
		cmp	#%11000000		;DAT+CLK = high?
    ELSEIF target_platform == 264
		lda	$01			;CPU port for handle serial lines
		and	#%11000000
		cmp	#%11000000		;DAT+CLK = high?
    ENDIF
		bne	$$waitcont
		rts
$$waitcont	cmp	$$state
		beq	$$waitcycle
		sta	$$state
		lda	#'.'
		jsr	rom_bsout
		jmp	$$waitcycle
$$state		BYT	0
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode	BINCLUDE "diskimgs-drive.bin"
_drivecode_end
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
;------------------------------------------------------------------------------
_resultsdata	RMB	255
_resultsdata_e
;------------------------------------------------------------------------------
