;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.10.16.+ by BSZ
;---	Send/Receive test, 1bit, drive side
;---	FSTXB/FSRXB commands on drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
vcpu_revno = 2
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
drivecode_start		=	$0200
drivecode_zptr		=	drivecode_start + $000
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
		ldzph	hi(_drive_databuffer)		;Set ZPH
		ldsph	hi(drivecode_sptr)		;Set SPH
		ldx	#$ff
		txs					;Set SP

		usckh				;Set CLK to HiZ
$$bigcycle	ldy	#$ff				;256 BYTEs receive/send back
		fsrxb					;Get BYTE
		cmp	#$00
		bne	$$run
		break	vcpu_syscall_exit_ok

$$run		ldx	#$00
$$recvcyc	fsrxb					;Get BYTE
		sta	lo(_drive_databuffer),x		;Save to buffer
		uindb	$$recvcyc			;X+, Y-, jump back

		ldy	#$7f
$$sendcyc	lda	lo(_drive_databuffer),x		;Load from buffer
		uwckl					;Wait for CLK Low
		fstxb					;Send BYTE
		inx
		lda	lo(_drive_databuffer),x		;Load from buffer
		uwckh					;Wait for CLK High
		fstxb					;Send BYTE
		uindb	$$sendcyc			;X+, Y-, jump back
		usdth					;Release DAT
		jmp	$$bigcycle
;------------------------------------------------------------------------------
	ALIGN	$0100
_drive_databuffer
;------------------------------------------------------------------------------
	SHARED	drivecode_start
	SHARED	def_linkchk_byte
;------------------------------------------------------------------------------
