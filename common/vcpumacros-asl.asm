;------------------------------------------------------------------------------
;---	SD2IEC VCPU macros
;---	"The Macroassembler AS"; "asl" version
;---	  http://john.ccac.rwth-aachen.de:8000/as/
;------------------------------------------------------------------------------
;---	VCPU interrupt codes:
vcpu_error_align	=	$80
vcpu_error_address	=	$40
vcpu_error_illegalfc	=	$20
vcpu_error_hangup	=	$10
vcpu_error_card		=	$08
vcpu_error_atn		=	$04
vcpu_error_rwaddr	=	$02
vcpu_functioncall	=	$01

;---	VCPU SYSCALL codes:
vcpu_syscall_exit_ok		=	$00
vcpu_syscall_exit_seterror	=	$01
vcpu_syscall_exit_fillederror	=	$02
vcpu_syscall_exit_remain	=	$03
vcpu_syscall_disableatnirq	=	$11
vcpu_syscall_enableatnirq	=	$12
vcpu_syscall_setfatparams	=	$13
vcpu_syscall_directcommand	=	$21
vcpu_syscall_directcommand_mem	=	$22
vcpu_syscall_open		=	$23
vcpu_syscall_open_mem		=	$24
vcpu_syscall_close		=	$25
vcpu_syscall_closeall		=	$26
vcpu_syscall_refillbuffer	=	$27
vcpu_syscall_getchannelparams	=	$28
vcpu_syscall_changedisk		=	$31

vcpu_paramoffset	=	96

vcpu_commandbuffer	=	$fc00
vcpu_errorbuffer	=	$fd00
vcpu_param_position	=	vcpu_errorbuffer + vcpu_paramoffset + 0
vcpu_param_lastused	=	vcpu_errorbuffer + vcpu_paramoffset + 1
vcpu_param_eoi		=	vcpu_errorbuffer + vcpu_paramoffset + 2

;---	I/O addresses:
vcpu_iobase		=	$fe00
vcpu_version		=	vcpu_iobase + $00
vcpu_unitno		=	vcpu_iobase + $01
vcpu_hid		=	vcpu_iobase + $02
vcpu_b2dconverter	=	vcpu_iobase + $07
vcpu_bin2decimal	=	vcpu_b2dconverter + 0
vcpu_bin2ascii		=	vcpu_b2dconverter + 1
vcpu_bin2result		=	vcpu_b2dconverter + 0
vcpu_bin2resultl	=	vcpu_bin2result + 0
vcpu_bin2resultm	=	vcpu_bin2result + 1
vcpu_bin2resulth	=	vcpu_bin2result + 2
vcpu_atnsrqout		=	vcpu_iobase + $0a
vcpu_atnsrqin		=	vcpu_iobase + $0b
vcpu_clkdatout		=	vcpu_iobase + $0c
vcpu_clkdatin		=	vcpu_iobase + $0d
vcpu_clkio		=	vcpu_iobase + $0e
vcpu_datio		=	vcpu_iobase + $0f
;------------------------------------------------------------------------------
;===	"SysCall":
break	MACRO	fcode
    IF ((fcode > 255) || (fcode < 0))
      ERROR "Parameter must be 0..255 range!"
    ENDIF
		BYT	$00, fcode
	ENDM

;===	SPH/ZPH:
tyzph	MACRO
		BYT	$44
	ENDM
tzphy	MACRO
		BYT	$54
	ENDM
ldzph	MACRO	addrhi
    ;IF ((addrhi > 255) || (addrhi < 0))
    ;  ERROR "Parameter must be 0..255 range!"
    ;ENDIF
		BYT	$02, addrhi
	ENDM
tysph	MACRO
		BYT	$d4
	ENDM
tsphy	MACRO
		BYT	$f4
	ENDM
ldsph	MACRO	addrhi
    ;IF ((addrhi > 255) || (addrhi < 0))
    ;  ERROR "Parameter must be 0..255 range!"
    ;ENDIF
		BYT	$22, addrhi
	ENDM

;	Binary to decimal ASCII chars:
btasc	MACRO
    ERROR "`BTASC` command deprecated. Use the converter peripheral instead."
	ENDM

;===	µOp codes:
;	UWDTL: Wait for DAT Low:
uwdtl	MACRO
		BYT	$03
	ENDM
;	UWDTH: Wait for DAT High:
uwdth	MACRO
		BYT	$13
	ENDM
;	UWCKL: Wait for CLK Low:
uwckl	MACRO
		BYT	$23
	ENDM
;	UWCKH: Wait for CLK High:
uwckh	MACRO
		BYT	$33
	ENDM
;	UWATL: Wait for ATN Low:
uwatl	MACRO
		BYT	$43
	ENDM
;	UWATH: Wait for ATN High:
uwath	MACRO
		BYT	$53
	ENDM

;	USDTL: Set DAT to Low:
usdtl	MACRO
		BYT	$83
	ENDM
;	USDTH: Set DAT to HighZ:
usdth	MACRO
		BYT	$93
	ENDM
;	USCKL: Set CLK to Low:
usckl	MACRO
		BYT	$a3
	ENDM
;	USCKH: Set CLK to HighZ:
usckh	MACRO
		BYT	$b3
	ENDM
;	USATL: Set ATN to Low:
usatl	MACRO
		BYT	$c3
	ENDM
;	USATH: Set ATN to HighZ:
usath	MACRO
		BYT	$d3
	ENDM

;	UCLDL: Set CLK to Low / DAT to Low:
ucldl	MACRO
		BYT	$0b
	ENDM
;	UCLDH: Set CLK to Low / DAT to HighZ:
ucldh	MACRO
		BYT	$1b
	ENDM
;	UCHDL: Set CLK to HighZ / DAT Low:
uchdl	MACRO
		BYT	$2b
	ENDM
;	UCHDH: Set CLK to HighZ / DAT to HighZ:
uchdh	MACRO
		BYT	$3b
	ENDM

;	UATDT: A register bit to DAT line:
uatdt	MACRO	bitmask
    IF ((bitmask > 255) || (bitmask < 0))
      ERROR "Parameter must be 0..255 range!"
    ENDIF
		BYT	$4b, bitmask
	ENDM
;	UDTTA: DAT line to A register bit:
udtta	MACRO	bitmask
    IF ((bitmask > 255) || (bitmask < 0))
      ERROR "Parameter must be 0..255 range!"
    ENDIF
		BYT	$5b, bitmask
	ENDM
;	UATCK: A register bit to CLK line:
uatck	MACRO	bitmask
    IF ((bitmask > 255) || (bitmask < 0))
      ERROR "Parameter must be 0..255 range!"
    ENDIF
		BYT	$6b, bitmask
	ENDM
;	UCKTA: CLK line to A register bit:
uckta	MACRO	bitmask
    IF ((bitmask > 255) || (bitmask < 0))
      ERROR "Parameter must be 0..255 range!"
    ENDIF
		BYT	$7b, bitmask
	ENDM
;	UATCD: A register bits to CLK/DAT lines:
uatcd	MACRO	clkbitmask, datbitmask
    IF ((clkbitmask > 255) || (clkbitmask < 0) || (datbitmask > 255) || (datbitmask < 0))
      ERROR "Parameters must be 0..255 range!"
    ENDIF
		BYT	$8b, clkbitmask, datbitmask
	ENDM
;	UCDTA: CLK/DAT lines to A register bits:
ucdta	MACRO	clkbitmask, datbitmask
    IF ((clkbitmask > 255) || (clkbitmask < 0) || (datbitmask > 255) || (datbitmask < 0))
      ERROR "Parameters must be 0..255 range!"
    ENDIF
		BYT	$9b, clkbitmask, datbitmask
	ENDM

;	ULBIT: Serial Lines "BIT" test:
ulbit	MACRO
		BYT	$db
	ENDM

;	UINDB: Increment X, Decrement Y, Branch if Y no underrun
uindb	MACRO	address
    IF (((address - * - 2) > 127) || ((address - * - 2) < -128))
      ERROR "Address too far!"
    ENDIF
		BYT	$ab, (address - * - 2)
	ENDM
;	UDEDB: Decrement X, Decrement Y, Branch if Y no underrun
udedb	MACRO	address
    IF (((address - * - 2) > 127) || ((address - * - 2) < -128))
      ERROR "Address too far!"
    ENDIF
		BYT	$bb, (address - * - 2)
	ENDM

;	USND1: Send A register bits to DAT
usnd1	MACRO
		BYT	$63
	ENDM
;	URCV1: Receive bits from DAT to A register
urcv1	MACRO
		BYT	$73
	ENDM
;	USND2: Send A register bitpairs to DAT/CLK
usnd2	MACRO
		BYT	$e3
	ENDM
;	URCV2: Receive bitpairs from DAT/CLK to A register
urcv2	MACRO
		BYT	$f3
	ENDM

;	UDELY: Delay "xT":
udely	MACRO	time
    IF ((time > 255) || (time < 0))
      ERROR "Parameter must be 0..255 range!"
    ENDIF
		BYT	$fb, time
	ENDM
;	UDLY1: Delay "1T":
udly1	MACRO
		BYT	$ea
	ENDM

;	UTEST:
utest	MACRO
		BYT	$eb
	ENDM
;------------------------------------------------------------------------------
