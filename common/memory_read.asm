;------------------------------------------------------------------------------
;---	SD2IEC VCPU memory read
;------------------------------------------------------------------------------
;---	After function call JSRs, requires 3 words:
;---	Start address of VCPU memory (source)
;---	Length of data
;---	Start address of computer memory (destination)

sd2i_readmemory

		tsx
		lda	$0101,x
		sta	$$paramread+1
		clc
		adc	#6
		sta	$0101,x
		lda	$0102,x
		sta	$$paramread+2
		adc	#0
		sta	$0102,x
		ldx	#1
		jsr	$$paramread
		sta	$$drvmemaddr+0
		jsr	$$paramread
		sta	$$drvmemaddr+1		;Read VCPU memory start address
		jsr	$$paramread
		sta	$$length+0
		jsr	$$paramread
		sta	$$length+1		;Read length
		jsr	$$paramread
		sta	$$writeaddr+1
		jsr	$$paramread
		sta	$$writeaddr+2		;Read destination start address

$$memrdcyc	jsr	$$getblocksize
		beq	$$memrdend
		lda	#%00000000
		sta	z_status
		lda	z_fa			;Unit No
		jsr	rom_listn
		lda	#$6f			;Command channel
		sta	z_sa
		jsr	rom_secnd
		lda	#'Z'
		jsr	rom_ciout
		lda	#'R'
		jsr	rom_ciout
		lda	$$drvmemaddr+0
		jsr	rom_ciout
		lda	$$drvmemaddr+1
		jsr	rom_ciout
		lda	$$blocksize
		jsr	rom_ciout		;"ZR" + VCPU (source) address + length
		jsr	rom_unlsn
		lda	#%00000000
		sta	z_status
		lda	z_fa			;Unit No
		jsr	rom_talk
		lda	#$6f			;Answer from error channel
		sta	z_sa
		jsr	rom_tksa
		ldy	#0
$$readdatacyc	bit	z_status
		bvs	$$dataend
		jsr	rom_acptr
$$writeaddr	sta	$ffff,y
		iny
		bne	$$readdatacyc
$$dataend	cpy	$$blocksize
		bne	$$datasizeerror
		jsr	rom_untlk
		jsr	$$addcompaddr
		jsr	$$adddrvaddr
		jmp	$$memrdcyc
$$memrdend	rts

$$datasizeerror	jsr	rom_primm
		BYT	ascii_return,"ERROR: MISSING BYTES!",ascii_return,0
		rts

;	Read parameter from table:
$$paramread	lda	$ffff,x
		inx
		rts

;	Calculate no. of bytes:
$$getblocksize	lda	$$length+1
		bne	$$maxblocksize
		lda	$$length+0
		cmp	#def_drvmem_rdblocksize
		bcc	$$setblocksize
$$maxblocksize	lda	#def_drvmem_rdblocksize
$$setblocksize	sta	$$blocksize
		sec
		lda	$$length+0
		sbc	$$blocksize
		sta	$$length+0
		lda	$$length+1
		sbc	#0
		sta	$$length+1
		lda	$$blocksize
		rts

;	Add transfered block size to computer address:
$$addcompaddr	clc
		lda	$$writeaddr+1
		adc	$$blocksize
		sta	$$writeaddr+1
		bcc	$$addcompaddr_o
		inc	$$writeaddr+2
$$addcompaddr_o	rts

;	Add transfered block size to VCPU address:
$$adddrvaddr	clc
		lda	$$drvmemaddr+0
		adc	$$blocksize
		sta	$$drvmemaddr+0
		bcc	$$adddrvaddr_o
		inc	$$drvmemaddr+1
$$adddrvaddr_o	rts

$$length	ADR	$0000
$$drvmemaddr	ADR	$0000
$$blocksize	BYT	0
;------------------------------------------------------------------------------
