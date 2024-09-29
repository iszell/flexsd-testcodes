;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2024.08.11.+ by BSZ
;---	Receive time test, parallel port, drive side
;---	PPDRD/PPDWR/PPACK/PPWAI commands on drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
vcpu_revno = 2
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $100
drivecode_sptr		=	drivecode_start + $000
def_linkchk_byte1	=	$5a
def_linkchk_byte2	=	$a5
;------------------------------------------------------------------------------
	ORG	drivecode_start

		ldzph	hi(_drive_databuffer)
		ldsph	hi(drivecode_sptr)
		ldx	#lo(drivecode_sptr + $ff)
		txs

		ldx	#0
$$gendata	txa
		sta	$00,x
		inx
		bne	$$gendata

		lda	#%11111111
		ppdwr				;Release PP lines
		lda	#def_linkchk_byte1	;$5A
		ucldh				;Set CLK to Low / DAT to HiZ
		uwdtl				;Wait for DAT low
		ppdwr				;Write data to PP
		ppack				;1µSec pulse on DRWP line
		lda	#def_linkchk_byte2	;$A5
		ppwai				;Wait previous data accept
		ppdwr				;Write data to PP
		ppack				;1µSec pulse on DRWP line
		lda	#%11111111		;$FF
		ppwai				;Wait previous data accept
		ppdwr				;Release parallel lines
		uchdh				;Release CLK+DAT lines
		uwdth				;Wait for DAT high

$$bigcycle	ldx	$$datastart
		uwdtl					;Wait for DAT low (Low pulse indicates to send cycle start)
		ppdrd					;Read PP lines: clear "new data" flag
		uwdth					;Wait for DAT high
		ppwai					;Wait new data
		ppdrd					;Get BYTE
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		tay					;x BYTE
		lda	$00,x
		ppdwr
		uindb	$$sendcyc
$$sendcyc	lda	$00,x
		ppwai
		ppdwr
		uindb	$$sendcyc
		ppwai
		lda	#%11111111
		ppdwr
		inc	$$datastart
		jmp	$$bigcycle

$$datastart	BYT	$00
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	def_linkchk_byte1
	SHARED	def_linkchk_byte2
;------------------------------------------------------------------------------
