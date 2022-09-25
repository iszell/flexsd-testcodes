;------------------------------------------------------------------------------
;---	Drive detect code (Low Level serial)
;---	Scan bus for units 8 to 15. Count active devices, search SD2IEC drive.
;------------------------------------------------------------------------------
    IFNDEF displaylevel
displev		SET	0
    ELSE
displev		SET	displaylevel
    ENDIF
;------------------------------------------------------------------------------
;---	A -> (last) SD2IEC Unit No
;---	X -> Units connected to serial bus

sd2i_scanning_bus

		lda	#8			;Start Unit No
		sta	z_fa
		lda	#0
		sta	$$unitfound
		sta	$$lastsd2iecno
$$checkdrive
    IF displev < 1
		jsr	$$printunitno
    ENDIF
		jsr	$$send_ui_comm
		bne	$$nounit
		jsr	$$recv_answer
		jsr	$$check_unittyp
		jmp	$$nextunit
$$nounit
    IF displev < 1
		jsr	$$printunitmiss
    ENDIF
$$nextunit	inc	z_fa
		lda	z_fa
		cmp	#16
		bne	$$checkdrive
		lda	$$lastsd2iecno		;SD2IEC Unit No
		ldx	$$unitfound		;Units connected to serial bus
		rts

;	Send "UI" command to (any) drive:
$$send_ui_comm	ldx	#lo($$ui_command)
		ldy	#hi($$ui_command)
		lda	#$$ui_command_end-$$ui_command
		jsr	sd2i_sendcommand
		lda	z_status
		and	#%10110000
		rts
$$ui_command	BYT	"UI"
$$ui_command_end

;	Read "answer" from error channel:
$$recv_answer	lda	#0
		ldy	#$$answer_end-$$answer-1
$$answerclr	sta	$$answer,y
		dey
		bpl	$$answerclr

		ldx	#lo($$answer)
		ldy	#hi($$answer)
		lda	#$$answer_end-$$answer
		jmp	sd2i_recvanswer

;	Check "answer":
;	"SD2IEC"/"1541"/"TDISK"/"1581"/"???"
$$check_unittyp
    IF target_platform = 264
		ldx	#4
$$check_ut_tdc	lda	$$answer+16,x
		cmp	$$drivetyp_1551,x
		bne	$$check_ut_ntd
		dex
		bpl	$$check_ut_tdc
      IF displev < 1
		jsr	rom_primm
		BYT	" 1551",0
      ENDIF
		rts
$$check_ut_ntd
    ENDIF
		inc	$$unitfound		;No TCBM drive, unit on serial bus, count
		ldx	#5
$$check_ut_sdc	lda	$$answer+3,x
		cmp	$$drivetyp_sd2i,x
		bne	$$check_ut_nsd
		lda	z_fa
		sta	$$lastsd2iecno		;Set SD2IEC Unit No
    IF displev < 1
		jsr	rom_primm
		BYT	" SD2IEC",0
    ENDIF
		rts
$$check_ut_nsd
    IF displev < 1
		jsr	rom_primm
		BYT	" 15XX (ANY SERIAL DRIVE)",0
    ENDIF
		rts

    IF target_platform = 264
$$drivetyp_1551	BYT	"TDISK"			;1551
    ENDIF
$$drivetyp_sd2i	BYT	"SD2IEC"		;SD2IEC

$$answer	BYT	"                "
		BYT	"                "
		BYT	"        "		;40 BYTE
$$answer_end
$$unitfound	BYT	0

$$lastsd2iecno	BYT	0

    IF displev < 1
$$printunitno	jsr	rom_primm
		BYT	ascii_return,"UNIT: #",0
		ldx	z_fa
		lda	#0
		jmp	bas_linprt
$$printunitmiss	jsr	rom_primm
		BYT	" [NONE]",0
		rts
    ENDIF
;------------------------------------------------------------------------------
displev		SET	0
;------------------------------------------------------------------------------
