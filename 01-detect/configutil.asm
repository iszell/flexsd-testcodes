;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2024.09.14.+ by BSZ
;---	Device configurator utility for 'a-detect'
;------------------------------------------------------------------------------
;	Include bus scanner without printing:
displaylevel	set	1
rescan_bus
	INCLUDE	"../common/drivedetect.asm"
	INCLUDE	"../common/waittime.asm"
def_resetdevwait	=	5	;5 sec. wait after device reset
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;---	Device configurator utility:
;---	It started out as a simple configuration tool, but
;---	  it got pretty chaotic in the meantime...

device_configurator
		jsr	printhorizontalline
		jsr	savedsettingsclear	;Clear saved settings

_rescan_restart	lda	#0
		sta	_exitrequest
		ldx	#_buttons_end-_buttons-1
$$butclr	sta	_buttons,x		;Clear usable buttons
		dex
		bpl	$$butclr

		jsr	rom_primm
    IF target_platform == 20
		BYT	ascii_return,$b0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ae
		BYT	ascii_return,$dd," DEV.CNFG UTILITY: ",$dd
		BYT	ascii_return,$ad,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$bd
    ELSE
		BYT	ascii_return,$b0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$ae
		BYT	ascii_return,$dd," DEVICE CONFIG UTILITY: ",$dd
		BYT	ascii_return,$ad,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0,$bd
    ENDIF
		BYT	0

		jsr	rescan_bus			;Rescan bus without print
		sta	z_fa				;Set SD2IEC Unit No
		sta	_newdeviceaddr			;Save for later use
		jsr	_printsd2iecuno			;Print SD2IEC unit no, if found
		bcc	$$devfound
		jmp	$$nodevcycle

$$devfound	jsr	getandprintsettings		;Get and print settings
		lda	_fasv				;Saved settings available?
		bne	$$savedsetsok
		jsr	settingssave			;Save current settings for later comparsion
$$savedsetsok	jsr	settingscompare
		bcc	$$setnochg
		jsr	setcolorred			;If settings changed, show '*'
		jsr	rom_primm
		BYT	"*",0
		jsr	restorecolor
$$setnochg	jsr	settingsparser			;Parse setting string

		jsr	rom_primm
		BYT	ascii_return,ascii_return,"  'SET CHANGE' MENU:"
    IF target_platform <> 20
		BYT	ascii_return
    ENDIF
		BYT	0

		lda	z_fa
		ldy	#'A'
		jsr	menu_addandprintbutton
		jsr	printset_deviceaddress

		lda	_set_extmode
		ldy	#'E'
		jsr	menu_addandprintbutton
		jsr	printset_extensmode

		lda	_set_exthiding
		ldy	#'H'
		jsr	menu_addandprintbutton
		jsr	printset_extenshiding

		lda	_set_postmatch
		ldy	#'*'
		jsr	menu_addandprintbutton
		jsr	printset_postmatching

		lda	_set_imageasdir
		ldy	#'I'
		jsr	menu_addandprintbutton
		jsr	printset_imageasdir

		lda	_set_dolphinpp
		ldy	#'P'
		jsr	menu_addandprintbutton
		jsr	printset_dolphinparport

		lda	_set_fastserial
		ldy	#'F'
		jsr	menu_addandprintbutton
		jsr	printset_fastserial

		lda	_set_romfnprsnt
		ldy	#'N'
		jsr	menu_addandprintbutton
		jsr	printset_dosromname

		ldy	#'!'
		tya
		jsr	menu_addandprintbutton
		jsr	rom_primm
		BYT	"RESET DEVICE",0

		ldy	#'S'
		tya
		jsr	menu_addandprintbutton
		jsr	rom_primm
    IF target_platform == 20
		BYT	"STORE CONFIG",0
    ELSE
		BYT	"STORE CONFIGURATION PERMANENTLY",0
    ENDIF

$$nodevcycle	ldy	#'R'
		tya
		jsr	menu_addandprintbutton
		jsr	rom_primm
		BYT	"RESCAN BUS",0

		ldy	#'X'
		tya
		jsr	menu_addandprintbutton
		jsr	rom_primm
		BYT	"EXIT",0
		ldy	#' '+$80
		tya
		jsr	menu_addandprintbutton



;	Menu on the screen, wait for selection:
		ldx	#lo(_buttons)
		ldy	#hi(_buttons)
		jsr	menu_printandwaitbttn	;Print all usable button and wait any usable button
		ldx	#0
$$functsrc	cmp	$$possiblebttns,x	;Search the function for pressed button
		beq	$$functfnd
		inx
		cpx	#$$possiblebttns_end-$$possiblebttns
		bne	$$functsrc
		rts				;?! This branch should not run

$$functfnd	txa
		asl	a
		tax
		lda	#hi($$commandexec-1)
		pha
		lda	#lo($$commandexec-1)
		pha
		lda	$$possiblefns+1,x
		pha
		lda	$$possiblefns+0,x
		pha
		jmp	printhorizontalline	;Print line, call function and go to continue

;	All buttons (not just the ones you can use) and their function addresses:
$$possiblebttns	BYT	" XRAEH*IPFN!S"
$$possiblebttns_end

$$possiblefns	ADR	changeset_exit-1
		ADR	changeset_exit-1
		ADR	changeset_rescan-1
		ADR	changeset_deviceaddress-1
		ADR	changeset_extensmode-1
		ADR	changeset_extenshiding-1
		ADR	changeset_postmatching-1
		ADR	changeset_imageasdir-1
		ADR	changeset_dolphinparport-1
		ADR	changeset_fastserial-1
		ADR	changeset_dosromname-1
		ADR	changeset_devicereset-1
		ADR	changeset_storesettings-1

;	Continue after the function call
;	Pass the command build by the function to the drive and ask for its response
$$commandexec	bcs	$$newcommand		;New command assembled?
		jmp	$$cyclerestart		;If no, next round

$$newcommand	jsr	rom_primm		;Print command string
		BYT	ascii_return,"S.CMD:'",0
		ldy	#0
$$printcommd	lda	_devconfigcomm,y
		cmp	#$20
		bcs	$$printcmd_asci
		jsr	setcolorred
		jsr	rom_primm
		BYT	'$',0
		jsr	mon_puthex
		jsr	restorecolor
		jmp	$$printcmd_next
$$printcmd_asci	jsr	rom_bsout
$$printcmd_next	iny
		cpy	_devconfcm_pos
		bne	$$printcommd
		jsr	rom_primm
		BYT	"'",0

		ldx	#lo(_devconfigcomm)	;Send command string to the drive
		ldy	#hi(_devconfigcomm)
		lda	_devconfcm_pos
		jsr	sd2i_sendcommand

		ldy	_waitaftercmd		;Wait required?
		beq	$$nowaitaftrcmd
		jsr	rom_primm
		BYT	ascii_return,"WAIT ",'0'+def_resetdevwait," SECS",0
		lda	#0
		sta	_waitaftercmd
$$waitasec	jsr	rom_primm
		BYT	".",0
		ldx	#def_irqpersec		;Interrupt / sec
		jsr	wait_frames
		dey
		bne	$$waitasec
		jsr	rom_primm
		BYT	"OVER.",0
;	This wait only runs when perform device reset. However, in some
;	cases the address of the device may change. For VIC20 and C64,
;	reading from a non-existent device will freeze. ('TKSA' not
;	return. Fortunately, there is no problem with writing.)
;	For this reason, in these platforms, the status query is
;	omitted here.
    IF ((target_platform == 20) || (target_platform == 64))
		jmp	$$cyclerestart
    ENDIF

$$nowaitaftrcmd	jsr	rom_primm		;Get and print device status
		BYT	ascii_return,"RCV.S:'",0
		lda	_newdeviceaddr
		sta	z_fa			;Set new device address (if changed, actual unit no set)
$$notnewdev	jsr	sd2i_printstatus	;Print command status
		jsr	rom_primm
		BYT	"'",0

$$cyclerestart	lda	_exitrequest
		bne	$$exitreq
    IF target_platform == 20
		jsr	_pressspace
    ENDIF
		jmp	_rescan_restart

$$exitreq	jsr	rom_primm
		BYT	ascii_return,ascii_return,"CONFIG UTILITY END",0
		rts
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;---	Configuration stuffs:
;------------------------------------------------------------------------------
;---	Print device address:
printset_deviceaddress
		jsr	rom_primm
    IF target_platform == 20
		BYT	"DEV.ADDR. (#",0
    ELSE
		BYT	"DEVICE ADDRESS (#",0
    ENDIF
		jsr	_printsd2iunoly
		jsr	rom_primm
		BYT	")",0
		rts

;---	Change device address:
changeset_deviceaddress
		jsr	printchangetext
		jsr	printset_deviceaddress
		jsr	rom_primm
		BYT	ascii_return
		BYT	ascii_return,ascii_rvson,"[8]",ascii_rvsoff,": ADDRESS #8"
		BYT	ascii_return,ascii_rvson,"[9]",ascii_rvsoff,": ADDRESS #9"
		BYT	ascii_return,ascii_rvson,"[A]",ascii_rvsoff,": ADDRESS #10"
		BYT	ascii_return,ascii_rvson,"[B]",ascii_rvsoff,": ADDRESS #11"
		BYT	ascii_return,ascii_rvson,"[C]",ascii_rvsoff,": ADDRESS #12"
		BYT	ascii_return,ascii_rvson,"[D]",ascii_rvsoff,": ADDRESS #13"
		BYT	ascii_return,ascii_rvson,"[E]",ascii_rvsoff,": ADDRESS #14"
		BYT	ascii_return,ascii_rvson,"[F]",ascii_rvsoff,": ADDRESS #15",0
		jsr	printxtocancel

		ldx	#lo($$buttontable)
		ldy	#hi($$buttontable)
		jsr	menu_printandwaitbttn	;Print all usable button and wait any usable button
		cpy	#8
		bcs	$$exit
		tya
		ora	#%00001000		;0..7 -> 8..15
		pha
		ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		pla				;A = new device address
		sta	_newdeviceaddr		;Save for later use (This is the devnum to request status from after the command is executed)
		jsr	writedevconfgch		;Add a new value
		sec				;SEC: New config command assembled
		rts
$$exit		clc				;CLC: No new config command
		rts

$$buttontable	BYT	"89ABCDEFX",' '+$80,0
$$devsetstr	BYT	"U0>",0		;"U0>"+dev.address



;---	Print extension mode:
printset_extensmode
		jsr	rom_primm
    IF target_platform == 20
		BYT	"EXT.MODE",0
    ELSE
		BYT	"EXTENSION MODE",0
    ENDIF
		lda	_set_extmode
		jmp	printvalue

;---	Change extension mode:
changeset_extensmode
		jsr	printchangetext
		jsr	printset_extensmode
		jsr	printseedoc
		jsr	rom_primm
		BYT	ascii_return,ascii_rvson,"[0]",ascii_rvsoff,": 0 (NEVER WRITE X00)"
		BYT	ascii_return,ascii_rvson,"[1]",ascii_rvsoff,": 1 (WRITE X00 S/U/R, NOT P) -DEF-"
		BYT	ascii_return,ascii_rvson,"[2]",ascii_rvsoff,": 2 (ALWAYS WRITE X00)"
		BYT	ascii_return,ascii_rvson,"[3]",ascii_rvsoff,": 3 (USE S/U/R EXT., NO X00 HEADER)"
		BYT	ascii_return,ascii_rvson,"[4]",ascii_rvsoff,": 4 (SAME AS 3, BUT ALSO FOR P)",0
		jsr	printxtocancel
		ldx	#lo($$buttontable)
		ldy	#hi($$buttontable)
		jsr	menu_printandwaitbttn	;Print all usable button and wait any usable button
		cpy	#5
		bcs	$$exit
		pha
		ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		pla				;A = new extension mode (ascii number / char)
		jsr	writedevconfgch		;Add a new value
		sec				;SEC: New config command assembled
		rts
$$exit		clc				;CLC: No new config command
		rts

$$buttontable	BYT	"01234X",' '+$80,0
$$devsetstr	BYT	"XE",0		;"XE0"/"XE1"/"XE2"/"XE3"/"XE4"



;---	Print extension hiding:
printset_extenshiding
		jsr	rom_primm
    IF target_platform == 20
		BYT	"EXT.HIDING",0
    ELSE
		BYT	"EXTENSION HIDING",0
    ENDIF
		lda	_set_exthiding
		jmp	printvalue

;---	Change extension hiding:
changeset_extenshiding
		jsr	printchangetext
		jsr	printset_extenshiding
		lda	#'D'			;Default: Disable
		jsr	selectorenabledisable
		bcs	$$exit
		pha
		ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		pla				;A.b0 = %0/%1 (disable / enable)
		jsr	writedevconfgmp		;Add "-"/"+"
		sec				;SEC: New config command assembled
		rts
$$exit		clc				;CLC: No new config command
		rts

$$devsetstr	BYT	"XE",0		;"XE-"/"XE+"



;---	Print post-* matching:
printset_postmatching
		jsr	rom_primm
    IF target_platform == 20
		BYT	"POST*MATCH",0
    ELSE
		BYT	"POST-* MATCHING",0
    ENDIF
		lda	_set_postmatch
		jmp	printvalue

;---	Change post-* matching:
changeset_postmatching
		jsr	printchangetext
		jsr	printset_postmatching
		lda	#'E'			;Default: Enable
		jsr	selectorenabledisable
		bcs	$$exit
		pha
		ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		pla				;A.b0 = %0/%1 (disable / enable)
		jsr	writedevconfgmp		;Add "-"/"+"
		sec				;SEC: New config command assembled
		rts
$$exit		clc				;CLC: No new config command
		rts

$$devsetstr	BYT	"X*",0		;"X*-"/"X*+"



;---	Print Image as Dir mode:
printset_imageasdir
		jsr	rom_primm
    IF target_platform == 20
		BYT	"IMAGE AS DIR",0
    ELSE
		BYT	"IMAGE AS DIR MODE",0
    ENDIF
		lda	_set_imageasdir
		jmp	printvalue

;---	Change Image as Dir mode:
changeset_imageasdir
		jsr	printchangetext
		jsr	printset_imageasdir
		jsr	printseedoc
		jsr	rom_primm
		BYT	ascii_return,ascii_rvson,"[0]",ascii_rvsoff,": 0 (IMAGE IS REGULAR FILE) -DEF-"
		BYT	ascii_return,ascii_rvson,"[1]",ascii_rvsoff,": 1 (IMAGE IS DIR ONLY)"
		BYT	ascii_return,ascii_rvson,"[2]",ascii_rvsoff,": 2 (IMAGE IS REGULAR FILE + DIR)",0
		jsr	printxtocancel
		ldx	#lo($$buttontable)
		ldy	#hi($$buttontable)
		jsr	menu_printandwaitbttn	;Print all usable button and wait any usable button
		cpy	#3
		bcs	$$exit
		pha
		ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		pla				;A = new extension mode (ascii number / char)
		jsr	writedevconfgch		;Add a new value
		sec				;SEC: New config command assembled
		rts
$$exit		clc				;CLC: No new config command
		rts

$$buttontable	BYT	"012X",' '+$80,0
$$devsetstr	BYT	"XI",0		;"XI0"/"XI1"/"XI2"



;---	Print DolphinDOS Parallel Port mode:
printset_dolphinparport
		jsr	rom_primm
    IF target_platform == 20
		BYT	"DD PARPORT",0
    ELSE
		BYT	"DOLPHIN DOS PARALLEL PORT",0
    ENDIF
		lda	_set_dolphinpp
		jmp	printvalue

;---	Change DolphinDOS Parallel port mode:
changeset_dolphinparport
		jsr	printchangetext
		jsr	printset_dolphinparport
		lda	#'D'			;Default: Disable
		jsr	selectorenabledisable
		bcs	$$exit
		pha
		ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		pla				;A.b0 = %0/%1 (disable / enable)
		jsr	writedevconfgmp		;Add "-"/"+"
		sec				;SEC: New config command assembled
		rts
$$exit		clc				;CLC: No new config command
		rts

$$devsetstr	BYT	"XP",0		;"XP-" / "XP+"



;---	Print Fast Serial mode:
printset_fastserial
		jsr	rom_primm
    IF target_platform == 20
		BYT	"FAST SER (",0
    ELSE
		BYT	"FAST SERIAL MODE (",0
    ENDIF
		lda	_set_fastserial
		bne	$$support
		jsr	rom_primm
		BYT	"N/A)",0
		rts
$$support	cmp	#'0'
		bne	$$not0
		jsr	rom_primm
		BYT	"DIS)",0
		rts
$$not0		cmp	#'1'
		bne	$$not1
		jsr	rom_primm
		BYT	"EN)",0
		rts
$$not1		cmp	#'2'
		bne	$$not2
		jsr	rom_primm
		BYT	"AUTO)",0
		rts
$$not2		jsr	rom_primm
    IF target_platform == 20
		BYT	"UNKWN)",0
    ELSE
		BYT	"UNKNOWN)",0
    ENDIF
		rts

;---	Change Fast Serial mode:
changeset_fastserial
		jsr	printchangetext
		jsr	printset_fastserial
		jsr	rom_primm
		BYT	ascii_return
		BYT	ascii_return,ascii_rvson,"[D]",ascii_rvsoff,": DISABLE -DEF-"
		BYT	ascii_return,ascii_rvson,"[E]",ascii_rvsoff,": ENABLE"
		BYT	ascii_return,ascii_rvson,"[A]",ascii_rvsoff,": AUTO MODE",0
		jsr	printxtocancel
		ldx	#lo($$buttontable)
		ldy	#hi($$buttontable)
		jsr	menu_printandwaitbttn	;Print all usable button and wait any usable button
		cpy	#3
		bcs	$$exit
		tya
		ora	#'0'
		pha
		ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		pla				;A = new extension mode (ascii number / char)
		jsr	writedevconfgch		;Add a new value
		sec				;SEC: New config command assembled
		rts
$$exit		clc				;CLC: No new config command
		rts

$$buttontable	BYT	"DEAX",' '+$80,0
$$devsetstr	BYT	"U0>B",0	;"U0>B0"/"U0>B1"/"U0>B2"



;---	Print DOS ROM filename:
printset_dosromname
		jsr	rom_primm
    IF target_platform == 20
		BYT	"DOS ROM N.(",0
    ELSE
		BYT	"DOS ROM NAME (",0
    ENDIF
		lda	_set_romfnprsnt
		bne	$$paramok
		jsr	rom_primm
		BYT	"N/A)",0
		rts
$$paramok	lda	_set_romfilenam+0	;First character from string
		bne	$$setdfn		;If not ø, parameter setted
		jsr	rom_primm
    IF target_platform == 20
		BYT	"N/S)",0
    ELSE
		BYT	"NOT SET)",0
    ENDIF
		rts
$$setdfn	jsr	rom_primm
		BYT	"'",0
		ldx	#0
$$fnprint	lda	_set_romfilenam,x
		beq	$$fnend
		jsr	rom_bsout
		inx
		cpx	#16
		bne	$$fnprint
$$fnend		jsr	rom_primm
		BYT	"')",0
		rts

;---	Change DOS ROM filename:
changeset_dosromname
		jsr	printchangetext
		jsr	printset_dosromname
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"EDIT DOS ROM FILENAME & PRESS "
		BYT	ascii_rvson,"[RETURN]",ascii_rvsoff
		BYT	ascii_return,"PRESS ",ascii_rvson,"[STOP]",ascii_rvsoff," TO CANCEL"
    IF target_platform == 20
		BYT	ascii_return,ascii_return,ascii_return,"    ================"
		BYT	ascii_up,ascii_up,ascii_return,"FNM:",0

    ELSE
		BYT	ascii_return,ascii_return,ascii_return,"         ================"
		BYT	ascii_up,ascii_up,ascii_return,"FILENAME:",0
    ENDIF
		lda	#16			;16 chars max
		ldx	#lo(_set_romfilenam)
		ldy	#hi(_set_romfilenam)	;Zero-terminated string buffer
		jsr	lineeditor
		bcc	$$edited
		jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,"CANCELED.",0
		clc
		rts

$$edited	jsr	rom_primm
		BYT	ascii_return,ascii_return,ascii_return,0
		tax
		bne	$$notclear
		ldx	#lo($$devsetstrclr)
		ldy	#hi($$devsetstrclr)
		jsr	copydevconfgstr		;Copy device configure string
		sec				;SEC: New config command assembled
		rts
$$notclear	ldx	#lo($$devsetstrset)
		ldy	#hi($$devsetstrset)
		jsr	copydevconfgstr		;Copy device configure string
		ldy	#0
$$addfn		lda	_set_romfilenam,y
		beq	$$endfn
		jsr	writedevconfgch
		iny
		cpy	#16
		bne	$$addfn
$$endfn		sec				;SEC: New config command assembled
		rts

$$devsetstrclr	BYT	"XR",0
$$devsetstrset	BYT	"XR:",0

;_set_romfilenam	BYT	[17]0



;---	Send (HW) RESET command to device:
changeset_devicereset
		jsr	rom_primm
		BYT	ascii_return,"RESETTING SD2IEC DEVICE (UNIT #",0
		jsr	_printsd2iunoly
		jsr	rom_primm
		BYT	")",ascii_return
		BYT	ascii_return,"WARNING: ALL SETTINGS ARE RESTORED TO"
		BYT	ascii_return,"THE STATE SAVED IN THE DEVICE!"
		BYT	ascii_return,ascii_return,"  ARE YOU SURE?",ascii_return,0
		jsr	selectorareyousure	;"ARE YOU SURE?"
		bcs	$$yesselect
		jsr	rom_primm
		BYT	ascii_return,"CANCELED.",0
		clc
		rts
$$yesselect	ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		jsr	savedsettingsclear	;Clear saved settings (copy a new one for use)
		lda	#def_resetdevwait
		sta	_waitaftercmd		;Wait 5 sec for device reset
		sec				;SEC: New config command assembled
		rts

$$devsetstr	BYT	"U",'J'+$80,0	;"U"+shift+"J": Device "hard" reset



;---	Send "store configuration permanently" command to device:
changeset_storesettings
		jsr	rom_primm
		BYT	ascii_return,"STORE CONFIGURATION",ascii_return,0
		jsr	settingscompare		;Compare saved settings / actual settings
		bcs	$$different
		jsr	rom_primm
		BYT	ascii_return,"NO CHANGE FROM THE INITIAL SETTINGS"
		BYT	ascii_return,"STORE ANYWAY?",ascii_return,0
		jmp	$$getyesno

$$different	jsr	rom_primm
		BYT	ascii_return,"SETTINGS CHANGED, SAVE?",ascii_return,0

$$getyesno	jsr	selectorareyousure	;"ARE YOU SURE?"
		bcs	setsave_yesselect
		clc
		rts

setsave_yesselect
		ldx	#lo($$devsetstr)
		ldy	#hi($$devsetstr)
		jsr	copydevconfgstr		;Copy device configure string
		jsr	savedsettingsclear	;Clear current settings, new settings will be saved later
		jsr	rom_primm
		BYT	ascii_return,"SETTINGS SAVE",ascii_return,0
		sec				;SEC: New config command assembled
		rts

$$devsetstr	BYT	"XW",0		;"XW": Store configuration to EEPROM



;---	Rescan bus:
changeset_rescan
		jsr	rom_primm
		BYT	ascii_return,"RESCAN DEVICES...",0
		clc				;CLC, no send config command
		rts



;---	EXIT from config utility:
changeset_exit	jsr	rom_primm
    IF target_platform == 20
		BYT	ascii_return,"EXIT DEV.CONF.UTILITY",0
    ELSE
		BYT	ascii_return,"EXIT DEVICE CONFIG UTILITY",0
    ENDIF
		jsr	settingscompare		;Compare saved settings / actual settings
		bcs	$$different
		jmp	$$same

$$different	jsr	rom_primm
		BYT	ascii_return
		BYT	ascii_return,"DEVICE SETTINGS HAVE CHANGED. THEY ARE"
		BYT	ascii_return,"ONLY VALID UNTIL THE FIRST DEVICE"
		BYT	ascii_return,"RESET! SAVES THE SETTINGS TO PERMANENT?",ascii_return,0
		jsr	selectorareyousure	;"ARE YOU SURE?"
		bcs	$$yesselect
		cmp	#"X"			;Cancel?
		beq	$$cancel
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"WARNING: SETTINGS NOT SAVED.",0
		jmp	$$same
$$yesselect	jsr	setsave_yesselect
		dec	_exitrequest		;Set exit
		sec				;SEC: New config command assembled
		rts

$$same		dec	_exitrequest		;Set exit
$$cancel	clc				;CLC, no send config command
		rts
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;---	Enable/Disable selector:
;---	A   <- "D"/"E"/any: select default
;---	A   -> 0,1,2,3,4,5,6,7 (B0=0: DISABLE, B0=1: ENABLE)
;---	Cy. -> 0: OK, 1: not selected!
selectorenabledisable
		jsr	rom_primm
		BYT	ascii_return
		BYT	ascii_return,ascii_rvson,"[D]",ascii_rvsoff,": DISABLE",0
		cmp	#'D'
		bne	$$notdefdis
		jsr	$$printdefault
$$notdefdis	jsr	rom_primm
		BYT	ascii_return,ascii_rvson,"[E]",ascii_rvsoff,": ENABLE",0
		cmp	#'E'
		bne	$$notdefen
		jsr	$$printdefault
$$notdefen	jsr	printxtocancel
		ldx	#lo($$buttontable)
		ldy	#hi($$buttontable)
		jsr	menu_printandwaitbttn	;Print all usable button and wait any usable button
		cpy	#6
		bcs	$$exit
		tya
$$exit		rts

$$printdefault	jsr	rom_primm
		BYT	" -DEF-",0
		rts

$$buttontable	BYT	"DE",'0'+$80,'1'+$80,'-'+$80,'+'+$80,'X',' '+$80,0

;---	"ARE YOU SURE?"
;---	Cy. -> 0: No
;---	       1: Yes
;---	A   -> Pressed button
selectorareyousure
		jsr	rom_primm
		BYT	ascii_return,ascii_rvson,"[Y]",ascii_rvsoff,": YES"
		BYT	ascii_return,ascii_rvson,"[N]",ascii_rvsoff,": NO",0
		jsr	printxtocancel
		ldx	#lo($$buttontable)
		ldy	#hi($$buttontable)
		jsr	menu_printandwaitbttn	;Print all usable button and wait any usable button
		cmp	#'Y'
		clc
		bne	$$exit
		sec
$$exit		rts

$$buttontable	BYT	"YNX",' '+$80,0
;------------------------------------------------------------------------------
;---	~MENU stuffs:

;---	Print all usable button and wait any usable button:
;	Y:X <- Enabled buttons list address
menu_printandwaitbttn
		stx	z_eal
		sty	z_eah		;Set buttontable

		jsr	rom_primm
		BYT	ascii_return,ascii_return,"# PRESS ",ascii_rvson,"[",0
		ldy	#0
$$buttonsprint	lda	(z_eal),y
		beq	$$buttonsend
		bmi	$$noprint
		jsr	rom_bsout
$$noprint	iny
		bne	$$buttonsprint			;~BRA
$$buttonsend	jsr	rom_primm
		BYT	"]",ascii_rvsoff," KEY TO SELECT",0

;		ldx	z_eal
;		ldy	z_eah			;Get buttontable
;
;;	Wait any enabled button:
;;	Y:X <- Enabled buttons list address
;;	A -> Pressed button ASCII code
;;	Y -> Index of enabled buttons list
;menu_waitbttn	stx	z_eal
;		sty	z_eah			;Set buttontable

$$waitkey	jsr	wait_keypress
		sta	$$pressedkey+1
		ldy	#0
$$keysearch	lda	(z_eal),y		;buttontable
		beq	$$waitkey
		and	#%01111111
$$pressedkey	cmp	#$00			;<- self-modified
		beq	$$keyfound
		iny
		bne	$$keysearch
		beq	$$waitkey
$$keyfound	jsr	rom_primm
		BYT	ascii_return,0
		rts

;---	For main menu: search empty button position and set
;---	Print to screen for menu
;---	Y <- Button to be set
;---	A <- != 0: set, else skip
menu_addandprintbutton
		cmp	#0
		beq	$$notset
		ldx	#0
		txa
$$search	cmp	_buttons,x
		beq	$$empty
		inx
		bne	$$search			;~BRA
$$empty		tya
		sta	_buttons,x			;Save to first unused position
		bmi	$$noprint
		jsr	rom_primm
		BYT	ascii_return,ascii_rvson,"[",0
		tya
		jsr	rom_bsout
		jsr	rom_primm
		BYT	"]",ascii_rvsoff,": ",0
		rts
$$notset	jsr	rom_primm
		BYT	ascii_return,"---: ",0
$$noprint	rts
;------------------------------------------------------------------------------
;---	New 'set command' building stuffs:

;---	Copy device configure string to buffer
;---	Clear buffer + pointer and copy zero-terminated string to buffer
;---	Y:X <- string address
copydevconfgstr	stx	z_sal
		sty	z_sah
		lda	#0
		sta	_devconfcm_pos
		ldy	#def_setstrmaxlen-1
$$clr		sta	_devconfigcomm,y
		dey
		bpl	$$clr
		iny
$$src		lda	(z_sal),y		;Read char from source
		beq	$$strend		;If ø, string end
		jsr	writedevconfgch		;Put char to buffer
		iny
		bne	$$src			;~BRA
$$strend	rts

;	Add "-" or "+" to device configuration command string:
writedevconfgmp	and	#%00000001
		bne	$$plus
		lda	#"-"
		bne	writedevconfgch
$$plus		lda	#"+"

;	Add one BYTE to device configuration command string:
writedevconfgch	ldx	_devconfcm_pos
		sta	_devconfigcomm,x
		inx
		stx	_devconfcm_pos
		rts
;------------------------------------------------------------------------------
;---	Text-stuffs:

;---	Print horizontal line:
printhorizontalline
		jsr	rom_primm
    IF target_platform == 20
		BYT	ascii_return,"---------------------",ascii_return,0
    ELSE
		BYT	ascii_return,"---------------------------------------",ascii_return,0
    ENDIF
		rts

;---	Print "[X]: CANCEL" string:
printxtocancel	jsr	rom_primm
		BYT	ascii_return,ascii_rvson,"[X]",ascii_rvsoff,": CANCEL",0
		rts

;---	Print "CHANGE " text (for all setting changer):
printchangetext	jsr	rom_primm
    IF target_platform == 20
		BYT	ascii_return,"CHNG.",0
    ELSE
		BYT	ascii_return,"CHANGE ",0
    ENDIF
		rts

;---	Print "SEE DOC" string:
printseedoc	jsr	rom_primm
		BYT	ascii_return,ascii_return,"FOR VALUES SEE SD2IEC DOCUMENTATION!",ascii_return,0
		rts

;---	Print boolean value (+/- -> EN/DIS) or any char (number)
printvalue	cmp	#'-'
		bne	$$notneg
		jsr	rom_primm
		BYT	" (DIS)",0
		rts
$$notneg	cmp	#'+'
		bne	$$notpos
		jsr	rom_primm
		BYT	" (EN)",0
		rts
$$notpos	cmp	#0		;Not available?
		beq	$$notavailable
		jsr	rom_primm
		BYT	" (",0
		jsr	rom_bsout
		jsr	rom_primm
		BYT	")",0
		rts
$$notavailable	jsr	rom_primm
		BYT	" (N/A)",0
		rts

;---	Printing color:
restorecolor	clc
		BYT	$24		;BIT $zp Op.Code
setcolorred	sec
		pha
		bcs	$$set
		lda	_colorsv
		bcc	$$reset
$$set		lda	_color
		sta	_colorsv
		lda	#error_color
$$reset		sta	_color
		pla
		rts

_colorsv	BYT	0
;------------------------------------------------------------------------------
;---	Line editor V0.1
;---	A   <- Max number of characters
;---	Y:X <- Zero-terminated string buffer
;---	Cy  -> 0: OK, 1: exit with STOP key

lineeditor	sta	$$maxlen
		stx	z_sal
		sty	z_sah			;Save buffer address

		ldy	#0
		sty	$$xpos
		sty	z_qtsw			;Clear quote mode
		sty	z_insrt			;Clear insert
$$origprint	lda	(z_sal),y
		beq	$$origend
		jsr	rom_bsout
		inc	$$xpos
		iny
		cpx	$$maxlen
		bne	$$origprint
$$origend

$$inputcycle	lda	#' '
		jsr	cursorandkey
		bcs	$$stop
		pha
		and	#%01111111		;Cut B7
		cmp	#32
		pla
		bcs	$$charokay
		cmp	#ascii_return
		beq	$$exitus
		cmp	#ascii_del
		bne	$$notdel
		ldx	$$xpos
		beq	$$newcharmore
		dec	$$xpos
		jsr	rom_bsout
		ldy	$$xpos
		lda	#0
		sta	(z_sal),y		;Clear character on buffer
		jmp	$$newcharmore

$$notdel
		bne	$$newcharmore
$$charokay	ldy	$$xpos
		cpy	$$maxlen
		bcs	$$newcharmore
		sta	(z_sal),y		;Save new character to buffer
		jsr	rom_bsout		;Print new character to screen
		lda	#0
		sta	z_qtsw			;Clear quote mode
		sta	z_insrt			;Clear insert
		iny
		sta	(z_sal),y		;Next char automatically ø (string end)
		inc	$$xpos
$$newcharmore	jmp	$$inputcycle		;~BRA

$$stop		sec
		BYT	$24			;BIT $xx Op.Code

$$exitus	clc
    IF (target_platform == 264) || (target_platform == 128)
		lda	#0
		sta	_kyndx
		sta	_keyidx			;Clear any function key press
    ENDIF
		lda	$$xpos			;Return new string length
		rts

$$xpos		BYT	0
$$maxlen	BYT	0

;---	Display cursor, wait key:
;---	A <- Cursor character (' ' <- Normal cursor)

cursorandkey	sta	$$cursorstr+1
		jsr	$$printcursor

		ldx	#0
		stx	z_ndx			;Clear Interrupt's keyboard buffer

$$wait		ldx	#ascii_rvsoff
		lda	z_time+2
		and	#%00010000
		cmp	$$savedtime
		beq	$$nocursortoggl
		sta	$$savedtime
		tay
		beq	$$noninv
		ldx	#ascii_rvson
$$noninv	stx	$$cursorstr+0
		jsr	$$printcursor

$$nocursortoggl
    IF target_platform == 20
		lda	#%00000001
    ELSE
		lda	#%10000000
    ENDIF
		bit	z_stkey			;STOP key pressed?
		beq	$$stoppressed
		lda	z_ndx
		beq	$$wait
		lda	_keyd+0			;Get ASCII code of pressed key
		clc				;CLC: OK, normal exit with RETURN key
		BYT	$24			;BIT $xxxx
$$stoppressed	sec				;SEC: STOP key pressed
		php
		pha
		lda	#0
		sta	z_ndx
		jsr	rom_primm
		BYT	" ",ascii_left,0
		pla
		plp
		rts

$$printcursor	jsr	rom_primm
$$cursorstr	BYT	ascii_rvson,"X",ascii_rvsoff,ascii_left,0
		rts

$$savedtime	BYT	0
;------------------------------------------------------------------------------
;---	Configuration string handling stuffs:

;---	Get and print SD2IEC device 'settings' string:
getandprintsettings
		ldx	#def_setstrmaxlen-1
		lda	#0
$$bufclr	sta	_devsetstring,x
		dex
		bpl	$$bufclr			;Clear settings string buffer

		ldx	#lo($$settingsstr)
		ldy	#hi($$settingsstr)
		lda	#$$settingsstr_len
		jsr	sd2i_sendcommand
		ldx	#lo(_devsetstring)
		ldy	#hi(_devsetstring)
		lda	#def_setstrmaxlen
		jsr	sd2i_recvanswer
		sty	_devsetstrlen			;Save answer length
		jsr	rom_primm
		BYT	ascii_return,"DEV.SET:",0
		ldy	#0
$$printres	lda	_devsetstring,y
		beq	$$end
		cmp	#ascii_return
		beq	$$end
		jsr	rom_bsout
		iny
		bne	$$printres
$$end		rts

$$settingsstr	BYT	"X"
$$settingsstr_len = * - $$settingsstr

;---	Save current settings for later comparsion:
settingssave	lda	z_fa
		sta	_fasv			;Save device address
		ldx	#def_setstrmaxlen-1
$$origsetcopy	lda	_devsetstring,x
		sta	_devsetstringsv,x	;Save configuration string
		dex
		bpl	$$origsetcopy
		rts

;---	Compare saved settings / actual settings
;---	Cy. -> 0: same
;---	       1: different
settingscompare	lda	_fasv
		cmp	z_fa			;Device address same?
		bne	$$changed
		ldx	#def_setstrmaxlen-1
$$setcmp	lda	_devsetstringsv,x
		cmp	_devsetstring,x
		bne	$$changed
		dex
		bpl	$$setcmp
		clc				;CLC: settings not changed
		rts
$$changed	sec				;SEC: settings changed
		rts

;---	Clear saved settings:
savedsettingsclear
		ldx	#def_setstrmaxlen-1
		lda	#0
		sta	_fasv			;Save device address clear
$$savesetclr	sta	_devsetstringsv,x	;Save configuration string clear
		dex
		bpl	$$savesetclr
		rts

;---	Not too elegant device settings string parser:
settingsparser	ldx	#_setblock_end-_setblock_start-1
		lda	#0
$$setblockclr	sta	_setblock_start,x
		dex				;Clear parsed settings
		bpl	$$setblockclr		;What remains 0 is a setting that is not supported

		tsx
		stx	$$spsave		;Save stack-pointer

		lda	_devsetstring+0
		cmp	#'0'
		bne	$$nosetstr
		lda	_devsetstring+1
		cmp	#'3'
		bne	$$nosetstr
		lda	_devsetstring+2
		cmp	#','			;  "03,"
		beq	$$setstr		;First fix. 3 char of string found?
$$nosetstr	jsr	rom_primm
		BYT	ascii_return,ascii_return,"WARNING: DEV.SET PARSE ERROR!",ascii_return,0
		rts

$$setstr	lda	_devsetstrlen		;  ",00,00[RETURN]__"
		sec
		sbc	#6+1			;  "_,_00,00[RETURN]"
		tax
		stx	$$offsetsave
		lda	_devsetstring+0,x
		sta	$$twobytes+0
		cmp	#','
		bne	$$nosetstr
		cmp	_devsetstring+3,x
		bne	$$nosetstr		;  ",xx,xx" / string end?
		lda	_devsetstring+1,x	;clear bytes after string end (restore after parser)
		sta	$$twobytes+1
		lda	#0
		sta	_devsetstring+0,x
		sta	_devsetstring+1,x	;clear bytes after string end (restore after parser)

		ldx	#3			;Skip "03,"
$$nextchar	jsr	$$getchar		;Get character from settings string
		tay
		jsr	$$getchar		;Get NEXT character from settings string

		cpy	#'E'			;Extension mode?
		bne	$$param_note
		jsr	$$getchar		;"0".."3"
		sta	_set_extmode		;Mode set to nonzero
		jsr	$$getchar		;"-"/"+"
		sta	_set_exthiding		;Extension hiding set to nonzero
		jmp	$$srcnextset_nx

$$param_note	cpy	#'*'			;Post-* match?
		bne	$$param_notasx
		sta	_set_postmatch		;"+"/"-", Postmatch set to nonzero
		jmp	$$srcnextset_nx

$$param_notasx	cpy	#'I'			;Image as Dir?
		bne	$$param_noti
		jsr	$$getchar		;"0".."2"
		sta	_set_imageasdir		;Image as Dir set to nonzero
		jmp	$$srcnextset_nx

$$param_noti	cpy	#'P'			;DolphinDOS parallel port support?
		bne	$$param_notp
		sta	_set_dolphinpp		;"+"/"-", DolphinDOS parallel port set to nonzero
		jmp	$$srcnextset_nx

$$param_notp	cpy	#'F'			;Fast serial mode?
		bne	$$param_notf
		sta	_set_fastserial		;"0".."2", Fast serial set to nonzero
		jmp	$$srcnextset_nx

$$param_notf	cpy	#'R'			;DOS ROM filename?
		bne	$$param_notr
		inc	_set_romfnprsnt		;Parameter present
		ldy	#0
$$param_r_copy	sta	_set_romfilenam,y
		jsr	$$getchar
		iny
		cpy	#16
		bne	$$param_r_copy
		beq	$$stringend		;The length of the DOS ROM filename is vary, so it is always the last parameter
$$param_notr
		dex				;"Undo" previously readed (and not used) parameter
$$srcnextset_c	cpy	#':'			;Separator?
		beq	$$nextchar		;If yes, go next
$$srcnextset_nx	jsr	$$getchar		;Unknown, search next set. Get character from settings string
		tay
		jmp	$$srcnextset_c

;	Get a character from dev.set string
;	X <- Actual index
;	A -> Character
;	X -> Next index
$$getchar	lda	_devsetstring,x
		bne	$$newchar
		lda	_devsetstring-1,x	;Previous char is ø?
		beq	$$stringend		;If yes, string end really
		lda	#$00			;Restore 0
$$newchar	cmp	#ascii_return
		beq	$$stringend		;If readed character = RETURN, end
		inx
		rts
$$stringend	ldx	$$spsave
		txs				;Restore SP
		ldx	$$offsetsave
		lda	$$twobytes+0
		sta	_devsetstring+0,x
		lda	$$twobytes+1
		sta	_devsetstring+1,x	;Restore cleared bytes (for compare)
		rts				;Return from settings parser subroutine

$$spsave	BYT	0
$$offsetsave	BYT	0
$$twobytes	BYT	0,0
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;	Working area:
_newdeviceaddr	BYT	0
_waitaftercmd	BYT	0
_exitrequest	BYT	0

;	Interpreted settings:
_setblock_start
_set_extmode	BYT	0		;Exx	: Extension mode
_set_exthiding	BYT	0		;-/+	: Extension hiding (E01-)
_set_postmatch	BYT	0		;+/-	: Post-* match (*+)
_set_imageasdir	BYT	0		;Ixx	: Image as Dir (0/1/2, I00)
_set_dolphinpp	BYT	0		;-/+	: DolphinDOS parallel port (P-)
_set_fastserial	BYT	0		;0/1/2	: Fast serial mode (F0)
_set_romfnprsnt	BYT	0		;ø	: If !0: param found, changeable
_set_romfilenam	BYT	[17]0
_setblock_end

;---	Device settings string:
_devsetstring	BYT	[def_setstrmaxlen]0
_devsetstrlen	BYT	0

;	Original settings string copy:
_devsetstringsv	BYT	[def_setstrmaxlen]0
_fasv		BYT	0

;	Configuration command string:
_devconfigcomm	BYT	[def_setstrmaxlen]0
_devconfcm_pos	BYT	0

;	Buttons storage for the menu:
_buttons	BYT	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
_buttons_end
;------------------------------------------------------------------------------
