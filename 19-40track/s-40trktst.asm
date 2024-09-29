;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.08.28.+ by BSZ
;---	Read/Wirte 40 track Disk Images, AutoSwap, computer side
;------------------------------------------------------------------------------
	INCLUDE	"_tempsyms_.inc"		;platform/name defines, generated / deleted automatically
	INCLUDE "../common/def6502.asm"
	INCLUDE	"../common/defines.asm"
;------------------------------------------------------------------------------
	INCLUDE	"../common/header.asm"
	INCLUDE	"../common/len_chks.asm"
	INCLUDE	"40trktst-drive.inc"
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,"SD2IEC 40 TRACK DISK IMAGES:",ascii_return,0

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
		BYT	" OK",ascii_return,"DOWNLOAD CODE TO DRV",0
		jsr	sd2i_writememory
		ADR	_drivecode
		ADR	_drivecode_end-_drivecode
		ADR	drivecode_start

;	First pass: check / write image in mounted mode:
		jsr	rom_primm
		BYT	ascii_return,"PASS #1:"
		BYT	ascii_return,"MOUNT IMAGE",0
		ldx	#lo(drivecode_init)
		ldy	#hi(drivecode_init)
		jsr	sd2i_execmemory_simple
		jsr	syncdrive
		jsr	getresults		;Get results from drive

		jsr	rom_primm
		BYT	ascii_return,"INIT RESULTS: ",0
		jsr	printresulthex
		lda	_resultslength
		cmp	#4
		bne	$$openerror
		lda	_resultsdata+0
		ora	_resultsdata+1
		ora	_resultsdata+3
		bne	$$openerror
		lda	_resultsdata+2
		cmp	#imageno
		beq	$$openokay
$$openerror	jsr	rom_primm
		BYT	" <- OPEN ERROR!",0
		jmp	$$exit

$$openokay	jsr	datainit		;Init

$$diskcycle1	jsr	rom_primm
		BYT	ascii_return,"READ/WRITE BLOCK DATA / TRK:",0
		lda	#0
		ldx	_htrack
		jsr	bas_linprt

		ldx	#lo(drivecode_onetrack)
		ldy	#hi(drivecode_onetrack)
		jsr	sd2i_execmemory_simple
		jsr	syncdrive
		jsr	getresults		;Get results from drive

		jsr	rom_primm
		BYT	ascii_scnclr,"BLOCKS DATA / TRK:",0
		lda	#0
		ldx	_htrack
		jsr	bas_linprt

		jsr	printtrackdatas
		bcc	$$ntrack1
		jmp	$$printerrexit1
$$ntrack1	inc	_htrack
		lda	_htrack
		cmp	#41			;40 track is over?
		bne	$$diskcycle1

$$printerrexit1	jsr	rom_primm
		BYT	ascii_return,"UMOUNT IMAGE",0
		ldx	#lo(drivecode_goback)
		ldy	#hi(drivecode_goback)
		jsr	sd2i_execmemory_simple
		jsr	syncdrive
		jsr	getresults		;Get results from drive
		jsr	rom_primm
		BYT	ascii_return,"EXIT RESULTS: ",0
		jsr	printresulthex
		lda	_resultslength
		cmp	#2
		bne	$$closeerror1
		lda	_resultsdata+0
		cmp	#$ff			;Line no error, this situation is good
		bne	$$closeerror1
		lda	_resultsdata+1
		cmp	#imageno+1		;SwapFile line next line is tests root dir
		beq	$$closeok1
$$closeerror1	jsr	rom_primm
		BYT	" <- COLOSE ERROR!",0
		jmp	$$exit

$$closeok1	jsr	rom_primm
		BYT	" <- OK",0
		lda	_firstrun+0
		ora	_firstrun+1
		beq	$$nofirstrun
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"FIRST RUN DETECTED. SECTOR DATA WRITTEN."
		BYT	ascii_return,"PLEASE RE-RUN THIS TEST!",0
$$nofirstrun	lda	_blockerr+0
		ora	_blockerr+1
		beq	$$noblockerr
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"BLOCK ERROR DETECTED. WRONG IMAGE SIZE?",0
$$noblockerr	lda	_dataerr+0
		ora	_dataerr+1
		beq	$$nodataerr
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"DATA ERROR DETECTED. WRONG IMAGE/FW?",0
$$nodataerr
		lda	_firstrun+0
		ora	_firstrun+1
		ora	_blockerr+0
		ora	_blockerr+1
		ora	_dataerr+0
		ora	_dataerr+1
		beq	$$firstpassok
$$exit		jmp	program_exit

;	Second pass: check image in raw file:
$$firstpassok	ldx	#100
		jsr	wait_frames			;Wait a bit
		jsr	rom_primm
		BYT	ascii_return,"PASS #2:"
		BYT	ascii_return,"OPEN IMAGE / RAW FILE",0
		ldx	#lo(drivecode_openfile)
		ldy	#hi(drivecode_openfile)
		jsr	sd2i_execmemory_simple
		jsr	syncdrive
		jsr	getresults		;Get results from drive

		jsr	rom_primm
		BYT	ascii_return,"OPEN IMAGE RESULTS: ",0
		jsr	printresulthex
		lda	_resultslength
		cmp	#1
		bne	$$opfilerror
		lda	_resultsdata+0
		beq	$$opfilokay
$$opfilerror	jsr	rom_primm
		BYT	" <- FILE OPEN ERROR!",0
		jmp	$$exit

$$opfilokay	jsr	datainit		;Init

$$diskcycle2	jsr	rom_primm
		BYT	ascii_return,"READ BLOCK DATA / COUNTED TRK:",0
		lda	#0
		ldx	_htrack
		jsr	bas_linprt

		ldx	#lo(drivecode_onetrkfromfile)
		ldy	#hi(drivecode_onetrkfromfile)
		jsr	sd2i_execmemory_simple
		jsr	syncdrive
		jsr	getresults		;Get results from drive

		jsr	rom_primm
		BYT	ascii_scnclr,"IMAGE DATA / TRK:",0
		lda	#0
		ldx	_htrack
		jsr	bas_linprt

		jsr	printtrackdatas
		bcc	$$ntrack2
		jmp	$$printerrexit2
$$ntrack2	inc	_htrack
		lda	_htrack
		cmp	#41			;40 track is over?
		bne	$$diskcycle2

$$printerrexit2	jsr	rom_primm
		BYT	ascii_return,"CLOSE IMAGE FILE",0
		ldx	#lo(drivecode_closefile)
		ldy	#hi(drivecode_closefile)
		jsr	sd2i_execmemory_simple
		jsr	syncdrive
		jsr	getresults		;Get results from drive
		jsr	rom_primm
		BYT	ascii_return,"EXIT RESULTS: ",0
		jsr	printresulthex
		lda	_resultslength
		cmp	#1
		bne	$$closeerror2
		lda	_resultsdata+0
		cmp	#$00			;OK?
		beq	$$closeok2
$$closeerror2	jsr	rom_primm
		BYT	" <- COLOSE ERROR!",0
		jmp	$$exit

$$closeok2	jsr	rom_primm
		BYT	" <- OK",0
		lda	_blockerr+0
		ora	_blockerr+1
		ora	_dataerr+0
		ora	_dataerr+1
		beq	$$bldaterr
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"BLOCK ERROR DETECTED. FILE ERROR?",0
$$bldaterr
		jmp	$$exit

;---	Print received answer in HEX BYTEs:
printresulthex	lda	_resultslength
		ldx	#lo(_resultsdata)
		ldy	#hi(_resultsdata)

;---	Print HEX BYTEs:
;---	A   <- number of BYTEs
;---	Y:X <- data address
printhexbytes	stx	$$print+1
		sty	$$print+2
		sta	$$length+1
		ldy	#0
$$print		lda	$ffff,y			;<- Self-modified
		jsr	mon_puthex
		iny
$$length	cpy	#$ff			;<- Self-modified
		bne	$$print
		rts

;---	Print track datas:
;---	Cy. -> 0: OK, 1: ERROR
printtrackdatas	ldx	_htrack
		lda	trackmaxsect,x		;Sectors / this track
		asl	a
		asl	a			;×4
		tax				;+1
		inx				;Number of expected bytes
		cpx	_resultslength		;Equal?
		beq	$$datalenok
		jsr	printresulthex		;Print result in HEX
		jsr	rom_primm
		BYT	" <- TRACK DATA ERROR!",0
		sec				;SEC: ERROR, exit cycle
		rts
$$datalenok	jsr	getbytefromresults	;Get Track number
		cmp	_htrack
		beq	$$tracknumok
		jsr	printresulthex		;Print result in HEX
		jsr	rom_primm
		BYT	" <- TRACK NUMBER ERROR!",0
		sec				;SEC: ERROR, exit cycle
		rts
$$tracknumok	lda	#0
		sta	_hsector		;Init sector number

$$sectcyc	ldx	#0
$$datacopy	jsr	getbytefromresults	;Get block data: track/sector/LBAlo/LBAhi
		sta	_oneblockdt,x
		inx
		cpx	#4
		bne	$$datacopy

		lda	_bltrack
		bpl	$$maybeokay
		jsr	rom_primm
		BYT	ascii_return," RCVD:",0
		ldx	#lo(_oneblockdt)
		ldy	#hi(_oneblockdt)
		lda	#4
		jsr	printhexbytes
		jsr	rom_primm
		BYT	" <- ERROR!",0
		inc	_blockerr+0
		bne	$$ncybe
		inc	_blockerr+1
$$ncybe		jmp	$$nextblock

$$maybeokay	jsr	rom_primm
		BYT	ascii_return," T:",0
		ldx	_bltrack
		lda	#0
		jsr	bas_linprt		;Print track no from block data
		jsr	rom_primm
		BYT	"/S:",0
		ldx	_blsect
		lda	#0
		jsr	bas_linprt		;Print sector no from block data
		jsr	rom_primm
    IF target_platform == 20
		BYT	"/LB:",0
    ELSE
		BYT	"/LBA:",0
    ENDIF
		ldx	_bllba+0
		lda	_bllba+1
		jsr	bas_linprt		;Print LBA from block data

		lda	_bltrack
		ora	_blsect
		ora	_bllba+0
		ora	_bllba+1		;All datas zero? (Maybe first run)
		bne	$$nofirstrun
		jsr	rom_primm
    IF target_platform == 20
		BYT	" FRUN?",0
    ELSE
		BYT	" FIRST RUN?",0
    ENDIF
		inc	_firstrun+0
		bne	$$nextblock
		inc	_firstrun+1
		jmp	$$nextblock
$$nofirstrun	lda	_bltrack
		cmp	_htrack
		bne	$$dataerr
		lda	_blsect
		cmp	_hsector
		bne	$$dataerr
		lda	_bllba+0
		cmp	_hlba+0
		bne	$$dataerr
		lda	_bllba+1
		cmp	_hlba+1
		bne	$$dataerr
		jsr	rom_primm
		BYT	" OK!",0
		jmp	$$nextblock

$$dataerr	jsr	rom_primm
		BYT	" <- WRONG DATA",0
		inc	_dataerr+0
		bne	$$nextblock
		inc	_dataerr+1

$$nextblock	inc	_hlba+0
		bne	$$ncy
		inc	_hlba+1
$$ncy		inc	_hsector
		lda	_hsector
		ldx	_htrack
		cmp	trackmaxsect,x		;Sectors / this track
		beq	$$trackend
		jmp	$$sectcyc
$$trackend	clc
		rts
;------------------------------------------------------------------------------
;---	Get results form drive:

getresults	jsr	waitdrive		;Wait for drive ready
		lda	#0
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

_resultspos	BYT	0
_resultslength	BYT	0
;------------------------------------------------------------------------------
;---	Init:
datainit	ldx	#0
		stx	_firstrun+0
		stx	_firstrun+1		;Clear "FirstRun" counter
		stx	_blockerr+0
		stx	_blockerr+1		;Clear "BlockError" counter
		stx	_dataerr+0
		stx	_dataerr+1		;Clear "DataError" counter
		;stx	_hsector		;(Clear later)
		stx	_hlba+1
		inx
		stx	_htrack
		stx	_hlba+0			;Set "host" Tr:Sec / LBA values
		rts
;------------------------------------------------------------------------------
;---	Sync drive:
;---	Wait for drivecode start, then generate High->Low->High pulse
syncdrive
    IF target_platform == 20
		lda	$911f			;VIA1 DRA
		and	#%00000011
		cmp	#%00000010		;DAT = High, CLK = Low?
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	$dd00			;CIA port for handle serial lines
		and	#%11000000
		cmp	#%10000000		;DAT = High, CLK = Low?
    ELSEIF target_platform == 264
		lda	$01			;CPU port for handle serial lines
		and	#%11000000
		cmp	#%10000000		;DAT = High, CLK = Low?
    ENDIF
		bne	syncdrive		;Wait for drivecode start

    IF target_platform == 20
		lda	#%11111100		;Drive DAT
		sta	$912c			;VIA2 PCR
		lda	#%11011100		;Release CLK/DAT
		sta	$912c			;VIA2 PCR
    ELSEIF (target_platform == 64) || (target_platform == 128)
		lda	$dd00
		and	#%00000111
		ora	#%00100000		;Drive DAT
		sta	$dd00
		and	#%00000111		;Release ATN/CLK/DAT
		sta	$dd00
    ELSEIF target_platform == 264
		lda	#%00001001		;Cas.Mtr Off, Drive DAT
		sta	$01
		lda	#%00001000		;Cas.Mtr Off, Release ATN/CLK/DAT
		sta	$01
    ENDIF
		rts


;---	Wait for drive ready:
waitdrive
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
		bne	waitdrive
		rts
;------------------------------------------------------------------------------
;	Number of sectors:
trackmaxsect
	INCLUDE	"maxsectors.asm"
;------------------------------------------------------------------------------
_htrack		BYT	0
_hsector	BYT	0
_hlba		ADR	$0000
_firstrun	ADR	$0000
_blockerr	ADR	$0000
_dataerr	ADR	$0000
;------------------------------------------------------------------------------
_oneblockdt
_bltrack	BYT	0
_blsect		BYT	0
_bllba		ADR	$0000
;------------------------------------------------------------------------------
;	Previously compiled drivecode binary:
_drivecode	BINCLUDE "40trktst-drive.bin"
_drivecode_end
;------------------------------------------------------------------------------
displaylevel	set	1
	INCLUDE	"../common/commerrchannel.asm"
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/checkvcpusupport.asm"
	INCLUDE "../common/memory_write.asm"
	INCLUDE	"../common/memory_execsimple.asm"
	INCLUDE	"../common/waittime.asm"
;------------------------------------------------------------------------------
_resultsdata	RMB	100
_resultsdata_e
;------------------------------------------------------------------------------
