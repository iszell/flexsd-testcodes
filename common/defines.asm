;------------------------------------------------------------------------------
;---	Defs:
;------------------------------------------------------------------------------
def_testcodes_version	=	"1.0"
;------------------------------------------------------------------------------
;---	Target platform:
;---		20	VIC20
;---		64	C64
;---		264	C264 series (C16 / C116 / plus/4)
;---		128	C128
;target_platform	=	264	;;; Defined by external
;------------------------------------------------------------------------------
;---	If target platfor is VIC20, set memory size:
;---		0: Default configuration, no any memory expansion
;---		3: +3K memory expansion only ($0400..$0FFF)
;---		8: +8K or more memory expansion ($2000..)
    IF target_platform = 20
vic20_setmem	=	0
    ENDIF
;------------------------------------------------------------------------------
ascii_return	=	13
ascii_down	=	17
ascii_rvson	=	18
ascii_esc	=	27
ascii_right	=	29
ascii_up	=	145
ascii_rvsoff	=	146
ascii_left	=	157
;------------------------------------------------------------------------------
def_drvmem_wrblocksize	=	96
def_drvmem_rdblocksize	=	80
;------------------------------------------------------------------------------
z_status	=	$90		;B Status
;------------------------------------------------------------------------------
;---	ROM entrys:

rom_listn	=	$ffb1		;Listen
rom_secnd	=	$ff93		;Secondary listen
rom_ciout	=	$ffa8		;busout
rom_unlsn	=	$ffae		;Unlisten
rom_talk	=	$ffb4		;Talk
rom_tksa	=	$ff96		;Secondary talk
rom_acptr	=	$ffa5		;busin
rom_untlk	=	$ffab		;Untalk
rom_bsout	=	$ffd2		;chrout ($0324)
;------------------------------------------------------------------------------
;---	Platform-dependent equates:

    IF target_platform = 20
;---	VIC20 RAM defs:
z_time		=	$a0		;B×3 Time, High:Mid:Low
z_sal		=	$ac		;B
z_sah		=	$ad		;B Load/Save Start Address
z_eal		=	$ae		;B
z_eah		=	$af		;B Load/Save End Address
z_la		=	$b8		;B Logical File number
z_sa		=	$b9		;B Secondary Address
z_fa		=	$ba		;B Unit No
z_ndx		=	$c6		;B Keyboard buffer index
_keyd		=	$0277		;B×10 Interrupt's Keyboard buffer
_color		=	$0286		;B Current color for character print (Active color nybble)
      IF vic20_setmem = 0
screen_addr	=	$1e00		;Screen mem address without RAM expansion
color_addr	=	$9600		;Color mem address
      ELSEIF vic20_setmem = 3
screen_addr	=	$1e00		;Screen mem address in +3K
color_addr	=	$9600		;Color mem address
      ELSEIF vic20_setmem = 8
screen_addr	=	$1000		;Screen mem address in +8K
color_addr	=	$9400		;Color mem address
      ELSE
	ERROR "No correct VIC20 memory size definied!"
      ENDIF
;---	VIC20 ROM entrys:
bas_linprt	=	$ddcd		;Print AX (unsigned integer, A = B15..8, X = B7..0)
rom_ser_clklo	=	$ef8d		;Serial line CLK to Lo
rom_ser_clkhi	=	$ef84		;Serial line CLK to HiZ
rom_ser_datlo	=	$e4a9		;Serial line DAT to Lo
rom_ser_dathi	=	$e4a0		;Serial line DAT to HiZ
rom_nirq	=	$eabf		;Original Interrupt routine
rom_prend	=	$eb18		;Interrupt end
;---	VIC20 others:
error_color	=	$02
scrclr_offset	=	30
def_blockno1	=	96
def_blockno2	=	160
def_rasterpos	=	68
    ELSEIF target_platform = 64
;---	C64 RAM defs:
z_time		=	$a0		;B×3 Time, High:Mid:Low
z_sal		=	$ac		;B
z_sah		=	$ad		;B Load/Save Start Address
z_eal		=	$ae		;B
z_eah		=	$af		;B Load/Save End Address
z_la		=	$b8		;B Logical File number
z_sa		=	$b9		;B Secondary Address
z_fa		=	$ba		;B Unit No
z_ndx		=	$c6		;B Keyboard buffer index
_keyd		=	$0277		;B×10 Interrupt's Keyboard buffer
_color		=	$0286		;B Current color for character print (Active color nybble)
screen_addr	=	$0400		;Screen mem address
color_addr	=	$d800		;Color mem address
;---	C64 ROM entrys:
bas_linprt	=	$bdcd		;Print AX (unsigned integer, A = B15..8, X = B7..0)
rom_ser_clklo	=	$ee8e		;Serial line CLK to Lo
rom_ser_clkhi	=	$ee85		;Serial line CLK to HiZ
rom_ser_datlo	=	$eea0		;Serial line DAT to Lo
rom_ser_dathi	=	$ee97		;Serial line DAT to HiZ
rom_nirq	=	$ea31		;Original Interrupt routine
rom_prend	=	$ea81		;Interrupt end
;---	C64 others:
error_color	=	$0a
scrclr_offset	=	64
def_vicbank	=	0		;Selected VIC BANK
def_cia_vicbank	=	%00000100 + ((def_vicbank ! 3) & 3)	;CIA register content
def_blockno1	=	144
def_blockno2	=	216
def_rasterpos	=	48
    ELSEIF target_platform = 264
;---	C16 / C116 / plus/4 RAM defs:
z_sal		=	$9b		;B
z_sah		=	$9c		;B Load/Save Start Address
z_eal		=	$9d		;B
z_eah		=	$9e		;B Load/Save End Address
z_time		=	$a3		;B×3 Time, High:Mid:Low
z_la		=	$ac		;B Logical File number
z_sa		=	$ad		;B Secondary Address
z_fa		=	$ae		;B Unit No
z_ndx		=	$ef		;B Keyboard buffer index
_keyd		=	$0527		;B×10 Interrupt's Keyboard buffer
_color		=	$053b		;B Current color for character print (Active attribute BYTE)
color_addr	=	$0800		;Color mem address
screen_addr	=	$0c00		;Screen mem address
;---	C16 / C116 / plus/4 ROM entrys:
bas_linprt	=	$a45f		;Print AX (unsigned integer, A = B15..8, X = B7..0)
mon_puthex	=	$fb10		;Print A (8 bit) in HEX
rom_ser_clklo	=	$e2bf		;Serial line CLK to Lo
rom_ser_clkhi	=	$e2b8		;Serial line CLK to HiZ
rom_ser_datlo	=	$e2cd		;Serial line DAT to Lo
rom_ser_dathi	=	$e2c6		;Serial line DAT to HiZ
rom_nirq	=	$ce0e		;Original Interrupt routine
rom_prend	=	$fcbe		;Interrupt end
rom_primm	=	$ff4f		;Print Immediate
;---	C16 / C116 / plus/4 others:
error_color	=	$32
scrclr_offset	=	64
def_blockno1	=	224
def_blockno2	=	256
def_rasterpos	=	311
    ELSEIF target_platform = 128
;---	C128 RAM defs:
z_time		=	$a0		;B×3 Time, High:Mid:Low
z_sal		=	$ac		;B
z_sah		=	$ad		;B Load/Save Start Address
z_eal		=	$ae		;B
z_eah		=	$af		;B Load/Save End Address
z_la		=	$b8		;B Logical File number
z_sa		=	$b9		;B Secondary Address
z_fa		=	$ba		;B Unit No
z_ndx		=	$d0		;B Keyboard buffer index
_keyd		=	$034a		;B×10 Interrupt's Keyboard buffer
_color		=	$f1		;B Current color for character print (Active color nybble)
screen_addr	=	$0400		;Screen mem address
color_addr	=	$d800		;Color mem address
;---	C128 ROM entrys:
bas_linprt	=	$8e32		;Print AX (unsigned integer, A = B15..8, X = B7..0)
mon_puthex	=	$b8c2		;Print A (8 bit) in HEX
rom_ser_clklo	=	$e54e		;Serial line CLK to Lo
rom_ser_clkhi	=	$e545		;Serial line CLK to HiZ
rom_ser_datlo	=	$e560		;Serial line DAT to Lo
rom_ser_dathi	=	$e557		;Serial line DAT to HiZ
rom_nirq	=	$fa65		;Original Interrupt routine
rom_prend	=	$ff33		;Interrupt end
rom_primm	=	$ff7d		;Print Immediate
;---	C128 others:
error_color	=	$0a
scrclr_offset	=	64
def_vicbank	=	0		;Selected VIC BANK
def_cia_vicbank	=	%00000100 + ((def_vicbank ! 3) & 3)	;CIA register content
def_blockno1	=	144
def_blockno2	=	216
def_rasterpos	=	48
    ELSE
	ERROR "No (correct) target_platform specified"
    ENDIF
;------------------------------------------------------------------------------
