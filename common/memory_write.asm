;------------------------------------------------------------------------------
;---	SD2IEC VCPU memory write
;------------------------------------------------------------------------------
;---	After function call JSRs, requires 3 word:
;---	Start address of downloadable data (source)
;---	Length of data
;---	Start address of VCPU memory (destination)

sd2i_writememory

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
		sta	$$senddata+1
		jsr	$$paramread
		sta	$$senddata+2		;Read drivecode start address (in computer memory)
		jsr	$$paramread
		sta	$$length+0
		jsr	$$paramread
		sta	$$length+1		;Read drivecode length
		jsr	$$paramread
		sta	$$drvmemaddr+0
		jsr	$$paramread
		sta	$$drvmemaddr+1		;Read Drive's memory start address

$$memwrcyc	jsr	$$getblocksize
		beq	$$memwrend
		lda	#%00000000
		sta	z_status
		lda	z_fa
		jsr	rom_listn
		lda	#$6f			;Command channel
		sta	z_sa
		jsr	rom_secnd
		lda	#'Z'
		jsr	rom_ciout
		lda	#'W'
		jsr	rom_ciout
		lda	$$drvmemaddr+0
		jsr	rom_ciout
		lda	$$drvmemaddr+1
		jsr	rom_ciout		;"ZW" + Drive destination address
		ldy	#0
$$senddata	lda	$ffff,y
		jsr	rom_ciout
		iny
$$blocksize	cpy	#$ff
		bne	$$senddata
		jsr	rom_unlsn
		jsr	$$addcompaddr
		jsr	$$adddrvaddr
		jmp	$$memwrcyc
$$memwrend	rts

;	Read parameter from table:
$$paramread	lda	$ffff,x
		inx
		rts

;	Calculate no. of bytes:
$$getblocksize	lda	$$length+1
		bne	$$maxblocksize
		lda	$$length+0
		cmp	#def_drvmem_wrblocksize
		bcc	$$setblocksize
$$maxblocksize	lda	#def_drvmem_wrblocksize
$$setblocksize	sta	$$blocksize+1
		sec
		lda	$$length+0
		sbc	$$blocksize+1
		sta	$$length+0
		lda	$$length+1
		sbc	#0
		sta	$$length+1
		lda	$$blocksize+1
		rts

;	Add transfered block size to computer address:
$$addcompaddr	clc
		lda	$$senddata+1
		adc	$$blocksize+1
		sta	$$senddata+1
		bcc	$$addcompaddr_o
		inc	$$senddata+2
$$addcompaddr_o	rts

;	Add transfered block size to VCPU address:
$$adddrvaddr	clc
		lda	$$drvmemaddr+0
		adc	$$blocksize+1
		sta	$$drvmemaddr+0
		bcc	$$adddrvaddr_o
		inc	$$drvmemaddr+1
$$adddrvaddr_o	rts

$$length	ADR	$0000
$$drvmemaddr	ADR	$0000
;------------------------------------------------------------------------------
