;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.10.17.+ by BSZ
;---	Receive time test, C128, Fast Serial, drive side
;---	FSTXB/FSRXB commands on drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
vcpu_revno = 2
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $100
drivecode_sptr		=	drivecode_start + $000
def_linkchk_byte	=	$50
;------------------------------------------------------------------------------
	ORG	drivecode_start

		ucldh				;Set CLK to Low / DAT to HiZ
		uwdtl				;Wait DAT to Low
		uwdth				;Wait DAT to High
		fsren				;Fast serial Receive enable
		lda	#def_linkchk_byte	;Link test data
		fstxb				;Send test data to host in Fast Serial
		usdth				;Set DAT to HiZ

		ldzph	hi(_drive_databuffer)
		ldsph	hi(drivecode_sptr)
		ldx	#lo(drivecode_sptr + $ff)
		txs

		ldx	#0
$$gendata	txa
		sta	$00,x
		inx
		bne	$$gendata

		usckh				;Set CLK to HiZ, ready

$$bigcycle	uwckh				;Wait CLK to high
		fsrxb				;Get BYTE
		cmp	#$00			;No. of BYTEs = 0?
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		tay				;x BYTE
		ldx	$$datastart

$$sendcyc	lda	$00,x
		uwckl				;Wait for CLK Low
		fstxb				;Send BYTE
		uindb	$$sendnext
		uchdh				;Release CLK/DAT
		inc	$$datastart
		jmp	$$bigcycle
$$sendnext	lda	$00,x
		uwckh				;Wait for CLK High
		fstxb				;Send BYTE
		uindb	$$sendcyc
		uchdh				;Release CLK/DAT
		inc	$$datastart
		jmp	$$bigcycle

$$datastart	BYT	$00
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	def_linkchk_byte
;------------------------------------------------------------------------------
