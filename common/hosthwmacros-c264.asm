;------------------------------------------------------------------------------
;---	Host HW handler macros for C264
;---	©2024.08.14.+ by BSZ
;------------------------------------------------------------------------------
;	Port to output:
pp_porttoout MACRO
    ENDM
;	Port to input:
pp_porttoin MACRO
		lda	#%11111111
		sta	$fd10
    ENDM

;	Write data to port:
pp_writeport MACRO
		ldx	#%00000000
		sta	$fd10			;Data to PP lines
		stx	$fd02			;RST line Low
		ldx	#%00001000
		stx	$fd02			;RST line High, generate HRWP manually
    ENDM
;	Read data from port:
pp_readport MACRO
		ldx	#%00000000
		lda	$fd10			;Data to PP lines
		stx	$fd02			;RST line Low
		ldx	#%00001000
		stx	$fd02			;RST line High, generate HRWP manually
    ENDM

;	Wait drive's R/W port pulse:
pp_waitdrwp MACRO
    ENDM
;	Check drive's R/W port flag:
pp_chkdrwp MACRO
		ldx	#$ff			;DRWP pulse present, lies
    ENDM
;	Clear drive's R/W port flag
pp_clrdrwp MACRO
    ENDM

;	HW init:
pp_hwinit MACRO
		pp_porttoin			;Set port direction to input
		lda	#%00000000
		sta	$fd03
		lda	#%00001000		;RTS / HRWP high
		sta	$fd02
    ENDM
;	HW deinit:
pp_hwdeinit MACRO
		pp_porttoin
		lda	#%00000000
		sta	$fd02			;ACIA command register to default
    ENDM

;	Wait for CLK line low:
ser_waitclklo MACRO
		bit	$01
		bvs	*-2
    ENDM

;	Set DAT line drive:
ser_setdat MACRO lev
      IF lev == 0
		lda	#%00001001
      ELSE
		lda	#%00001000
      ENDIF
		sta	$01
    ENDM

;	Get CLK+DAT line state:
ser_getclkdat MACRO
		lda	$01
		cmp	$01
		bne	*-4
		asl	a		;DAT -> Cy, CLK -> N
    ENDM
;------------------------------------------------------------------------------
