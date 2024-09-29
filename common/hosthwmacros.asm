;------------------------------------------------------------------------------
;---	Host HW handler macros
;---	©2024.08.14.+ by BSZ
;------------------------------------------------------------------------------
;---	Platform-dependant macro definitions:

    IF target_platform == 20
	INCLUDE "hosthwmacros-vic20.asm"
    ELSEIF (target_platform == 64) || (target_platform == 128)
	INCLUDE "hosthwmacros-c64c128.asm"
    ELSEIF target_platform == 264
	INCLUDE "hosthwmacros-c264.asm"
    ENDIF

;------------------------------------------------------------------------------
;---	Platform-independant macro definitions:

;	Start transmit/receive:
ser_starttransfer MACRO
		ser_setdat 0			;DAT drive to Low
		pp_clrdrwp			;Clear DRWP flag
		ser_setdat 1			;DAT release
    ENDM
;------------------------------------------------------------------------------
