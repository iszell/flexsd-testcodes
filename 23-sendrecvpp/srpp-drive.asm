;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2024.07.14.+ by BSZ
;---	Send/Receive test, Parallel port, drive side
;---	PPDRD/PPDWR/PPACK/PPWAI commands on drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
vcpu_revno = 2
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
drivecode_sptr		=	drivecode_start + $000
def_linkchk_byte1	=	$5a
def_linkchk_byte2	=	$a5
;------------------------------------------------------------------------------
	ORG	drivecode_start

		ldzph	hi(_drive_databuffer)	;Set ZPH
		ldsph	hi(drivecode_sptr)	;Set SPH
		ldx	#$ff
		txs				;Set SP

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

$$bigcycle	ldy	#$ff				;256 BYTEs receive/send back
		uwdtl					;Wait for DAT low (Low pulse indicates to send cycle start)
		ppdrd					;Read PP lines: clear "new data" flag
		uwdth					;Wait for DAT high
		ppwai					;Wait new data
		ppdrd					;Get BYTE
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		ldx	#$00
$$recvcyc	ppack					;1µSec pulse on DRWP line
		ppwai					;Wait new data
		ppdrd					;Get BYTE
		sta	lo(_drive_databuffer),x		;Save to buffer
		uindb	$$recvcyc			;X+, Y-, jump back
		ppack					;1µSec pulse on DRWP line (last "ACK")

		ldy	#$ff-1				;256 BYTEs
		lda	lo(_drive_databuffer),x		;Load from buffer
		inx
		uwdtl					;Wait for DAT low (Low pulse indicates to recv cycle start)
		uwdth					;Wait for DAT high
		ppdwr					;Write data to PP
		ppack					;1µSec pulse on DRWP line
$$sendcyc	ppwai					;Wait for data accept
		lda	lo(_drive_databuffer),x		;Load from buffer
		ppdwr					;Write data to PP
		ppack					;1µSec pulse on DRWP line
		uindb	$$sendcyc			;X+, Y-, jump back
		ppwai					;Wait for last data accept
		lda	#%11111111
		ppdwr					;Release parallel lines
		jmp	$$bigcycle
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	def_linkchk_byte1
	SHARED	def_linkchk_byte2
;------------------------------------------------------------------------------
