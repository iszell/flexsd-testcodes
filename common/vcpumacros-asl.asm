;------------------------------------------------------------------------------
;---	SD2IEC VCPU macros
;---	"The Macroassembler AS"; "asl" version
;---	  http://john.ccac.rwth-aachen.de:8000/as/
;---	V1.3.0
;------------------------------------------------------------------------------
    IFNDEF vcpu_revno
vcpu_revno	=	1	;If not defined, VCPU R1 is default
    ENDIF
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
vcpu_memiosize		=	vcpu_iobase + $01
vcpu_diag		=	vcpu_iobase + $01
vcpu_hid		=	vcpu_iobase + $02
vcpu_unitno		=	vcpu_iobase + $03
vcpu_dbguart		=	vcpu_iobase + $04
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
vcpu_parport_data	=	vcpu_iobase + $10
vcpu_parport_misc	=	vcpu_iobase + $11
;------------------------------------------------------------------------------
;===	"SysCall":
break	MACRO	fcode
  IF ((fcode > 255) || (fcode < 0))
    FATAL "`BREAK`: Parameter must be 0..255 range!"
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
  IF MOMPASS > 1
    IF ((addrhi > 255) || (addrhi < 0))
      ERROR "`LDZPH`: Parameter must be 0..255 range!"
    ENDIF
  ENDIF
		BYT	$02, addrhi
	ENDM
tysph	MACRO
		BYT	$d4
	ENDM
tsphy	MACRO
		BYT	$f4
	ENDM
ldsph	MACRO	addrhi
  IF MOMPASS > 1
    IF ((addrhi > 255) || (addrhi < 0))
      ERROR "`LDSPH`: Parameter must be 0..255 range!"
    ENDIF
  ENDIF
		BYT	$22, addrhi
	ENDM

    IF vcpu_revno >= 2
;	Fast call / return:
userr	MACRO
		BYT	$0f
	ENDM
user1	MACRO
		BYT	$1f
	ENDM
user2	MACRO
		BYT	$2f
	ENDM
;	RR/U1R/U2R (vector registers) handle:
tyxu1	MACRO
		BYT	$cb, %00000010
	ENDM
tu1yx	MACRO
		BYT	$cb, %00000011
	ENDM
tyxu2	MACRO
		BYT	$cb, %00000100
	ENDM
tu2yx	MACRO
		BYT	$cb, %00000101
	ENDM
tyxrr	MACRO
		BYT	$cb, %00000110
	ENDM
trryx	MACRO
		BYT	$cb, %00000111
	ENDM
pulrr	MACRO
		BYT	$cb, %00000000
	ENDM
pshrr	MACRO
		BYT	$cb, %00000001
	ENDM
    ENDIF

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
    ERROR "`UATDT`: Parameter must be 0..255 range!"
  ENDIF
		BYT	$4b, bitmask
	ENDM
;	UDTTA: DAT line to A register bit:
udtta	MACRO	bitmask
  IF ((bitmask > 255) || (bitmask < 0))
    ERROR "`UDTTA`: Parameter must be 0..255 range!"
  ENDIF
		BYT	$5b, bitmask
	ENDM
;	UATCK: A register bit to CLK line:
uatck	MACRO	bitmask
  IF ((bitmask > 255) || (bitmask < 0))
    ERROR "`UATCK`: Parameter must be 0..255 range!"
  ENDIF
		BYT	$6b, bitmask
	ENDM
;	UCKTA: CLK line to A register bit:
uckta	MACRO	bitmask
  IF ((bitmask > 255) || (bitmask < 0))
    ERROR "`UCKTA`: Parameter must be 0..255 range!"
  ENDIF
		BYT	$7b, bitmask
	ENDM
;	UATCD: A register bits to CLK/DAT lines:
uatcd	MACRO	clkbitmask, datbitmask
  IF ((clkbitmask > 255) || (clkbitmask < 0) || (datbitmask > 255) || (datbitmask < 0))
    ERROR "`UATCD`: Both parameters must be 0..255 range!"
  ENDIF
		BYT	$8b, clkbitmask, datbitmask
	ENDM
;	UCDTA: CLK/DAT lines to A register bits:
ucdta	MACRO	clkbitmask, datbitmask
  IF ((clkbitmask > 255) || (clkbitmask < 0) || (datbitmask > 255) || (datbitmask < 0))
    ERROR "`UCDTA`: Both parameters must be 0..255 range!"
  ENDIF
		BYT	$9b, clkbitmask, datbitmask
	ENDM

;	ULBIT: Serial Lines "BIT" test:
ulbit	MACRO
		BYT	$db
	ENDM

;	UINDB: Increment X, Decrement Y, Branch if Y no underrun:
uindb	MACRO	address
  IF MOMPASS > 1
    IF ((((address) - * - 2) > 127) || (((address) - * - 2) < -128))
      ERROR "`UINDB`: Address too far!"
    ENDIF
  ENDIF
		BYT	$ab, ((address) - * - 2)
	ENDM
;	UDEDB: Decrement X, Decrement Y, Branch if Y no underrun:
udedb	MACRO	address
  IF MOMPASS > 1
    IF ((((address) - * - 2) > 127) || (((address) - * - 2) < -128))
      ERROR "`UDEDB`: Address too far!"
    ENDIF
  ENDIF
		BYT	$bb, ((address) - * - 2)
	ENDM

;	USND1: Send A register bits to DAT:
usnd1	MACRO
		BYT	$63
	ENDM
;	URCV1: Receive bits from DAT to A register:
urcv1	MACRO
		BYT	$73
	ENDM
;	USND2: Send A register bitpairs to DAT/CLK:
usnd2	MACRO
		BYT	$e3
	ENDM
;	URCV2: Receive bitpairs from DAT/CLK to A register:
urcv2	MACRO
		BYT	$f3
	ENDM

    IF vcpu_revno >= 2
;	FSTXB: Fast Serial Transmit BYTE (send to host):
fstxb	MACRO
		BYT	$8f
	ENDM
;	FSRXB: Fast Serial Receive BYTE (receive from host):
fsrxb	MACRO
		BYT	$9f
	ENDM
;	FSRXC: Fast Serial Received flag check:
fsrxc	MACRO
		BYT	$af
	ENDM
;	FSRDS: Fast Serial Receiver disable:
fsrds	MACRO
		BYT	$cb, %00010000
	ENDM
;	FSREN: Fast Serial Receiver enable:
fsren	MACRO
		BYT	$cb, %00010001
	ENDM

;	PPACK: Parallel Port send ACK pulse to host:
ppack	MACRO
		BYT	$07
	ENDM
;	PPDRD: Parallel Port Data ReaD:
ppdrd	MACRO
		BYT	$17
	ENDM
;	PPDWR: Parallel Port Data WRite:
ppdwr	MACRO
		BYT	$27
	ENDM
;	PPWAI: Parallel Port WAIt ack pulse:
ppwai	MACRO
		BYT	$37
	ENDM
;	PPWDW: Parallel Port Wait ack pulse and Data Write:
ppwdw	MACRO
		BYT	$47
	ENDM

    ENDIF

;	UDELY: Delay "xT":
udely	MACRO	time
  IF ((time > 255) || (time < 0))
    ERROR "`UDELY': Parameter must be 0..255 range!"
  ENDIF
		BYT	$fb, time
	ENDM
;	UDLY1: Delay "1T":
udly1	MACRO
		BYT	$ea
	ENDM
;------------------------------------------------------------------------------
