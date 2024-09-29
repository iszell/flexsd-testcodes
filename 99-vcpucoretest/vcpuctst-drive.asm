;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.09.17.+ by BSZ
;---	VCPU core test codes - drive side
;------------------------------------------------------------------------------
	INCLUDE "../common/def6502.asm"
vcpu_revno = 2
	INCLUDE	"../common/vcpumacros-asl.asm"
;------------------------------------------------------------------------------
def_drivecodestart	=	$0200
def_exitcode		=	$ee
def_offset		=	$1000
	ORG	def_offset
;------------------------------------------------------------------------------
;---	Test0: SysCall test

dc_test0_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t0_start
		break	def_exitcode		;SysCall with invalid function code
	DEPHASE
dc_test0_codeend	=	* - def_offset

	SHARED	dc_test0_codestart
	SHARED	dc_test0_codeend
	SHARED	dc_t0_start
;------------------------------------------------------------------------------
;---	Test1: Illegal opcode

dc_test1_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t1_start
		BYT	$fc			;"NOP $xxxx" illegal code
		break	def_exitcode
	DEPHASE
dc_test1_codeend	=	* - def_offset

	SHARED	dc_test1_codestart
	SHARED	dc_test1_codeend
	SHARED	dc_t1_start
;------------------------------------------------------------------------------
;---	Test2: LDA/X/Y #$gh tests

dc_t2_data1	=	$45
dc_t2_data2	=	$67
dc_t2_data3	=	$89

dc_test2_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t2_start
		lda	#dc_t2_data1
		ldx	#dc_t2_data2
		ldy	#dc_t2_data3
		break	def_exitcode
	DEPHASE
dc_test2_codeend	=	* - def_offset

	SHARED	dc_test2_codestart
	SHARED	dc_test2_codeend
	SHARED	dc_t2_start
	SHARED	dc_t2_data1
	SHARED	dc_t2_data2
	SHARED	dc_t2_data3
;------------------------------------------------------------------------------
;---	Test3: STA $xxxx / STX $yyyy / STY $zzzz tests

dc_t3_data1	=	$ab
dc_t3_data2	=	$cd
dc_t3_data3	=	$ef

dc_test3_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t3_start
		lda	#dc_t3_data1
		ldx	#dc_t3_data2
		ldy	#dc_t3_data3
		sta	dc_t3_tstbs+0
		stx	dc_t3_tstbs+1
		sty	dc_t3_tstbs+2
		break	def_exitcode
dc_t3_tstbs	BYT	1,1,1
	DEPHASE
dc_test3_codeend	=	* - def_offset

	SHARED	dc_test3_codestart
	SHARED	dc_test3_codeend
	SHARED	dc_t3_start
	SHARED	dc_t3_data1
	SHARED	dc_t3_data2
	SHARED	dc_t3_data3
	SHARED	dc_t3_tstbs
;------------------------------------------------------------------------------
;---	Test4: SPH/ZPH set test, memory, command and error channel region tests

dc_t4_testsp	=	$0300
dc_t4_testzp	=	$0200

dc_test4_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t4_start
		nop
		break	def_exitcode
_test4_bad1	ldy	#$ee
		tysph				;<- Address error!
_test4_bad2	ldy	#$ee
		tyzph				;<- Address error!
_test4_good1	ldy	#$ee
		tysph
_test4_good2	ldy	#$ee
		tyzph
		break	def_exitcode
_test4_good3	ldsph	$ee
_test4_good4	ldzph	$ee
		break	def_exitcode
_test4_good5	lda	$ffff
_test4_good6	sta	$ffff
_test4_bad3	lda	$ff00
_test4_bad4	sta	$ff00
_test4_good7	lda	vcpu_commandbuffer+$fe
_test4_good8	sta	vcpu_commandbuffer+$fe
_test4_bad5	lda	vcpu_commandbuffer+$ff
_test4_bad6	sta	vcpu_commandbuffer+$ff
_test4_good9	lda	vcpu_errorbuffer+$fe
_test4_good10	sta	vcpu_errorbuffer+$fe
_test4_bad7	lda	vcpu_errorbuffer+$ff
_test4_bad8	sta	vcpu_errorbuffer+$ff
		break	def_exitcode
	DEPHASE
dc_test4_codeend	=	* - def_offset

dc_test4_bad1		=	_test4_bad1 - def_drivecodestart + dc_test4_codestart
dc_test4_bad2		=	_test4_bad2 - def_drivecodestart + dc_test4_codestart
dc_test4_good1		=	_test4_good1 - def_drivecodestart + dc_test4_codestart
dc_test4_good2		=	_test4_good2 - def_drivecodestart + dc_test4_codestart
dc_test4_good3		=	_test4_good3 - def_drivecodestart + dc_test4_codestart
dc_test4_good4		=	_test4_good4 - def_drivecodestart + dc_test4_codestart
dc_test4_good5		=	_test4_good5 - def_drivecodestart + dc_test4_codestart
dc_test4_good6		=	_test4_good6 - def_drivecodestart + dc_test4_codestart
dc_test4_bad3		=	_test4_bad3 - def_drivecodestart + dc_test4_codestart
dc_test4_bad4		=	_test4_bad4 - def_drivecodestart + dc_test4_codestart
dc_test4_good7		=	_test4_good7 - def_drivecodestart + dc_test4_codestart
dc_test4_good8		=	_test4_good8 - def_drivecodestart + dc_test4_codestart
dc_test4_good9		=	_test4_good9 - def_drivecodestart + dc_test4_codestart
dc_test4_good10		=	_test4_good10 - def_drivecodestart + dc_test4_codestart
dc_test4_bad5		=	_test4_bad5 - def_drivecodestart + dc_test4_codestart
dc_test4_bad6		=	_test4_bad6 - def_drivecodestart + dc_test4_codestart
dc_test4_bad7		=	_test4_bad7 - def_drivecodestart + dc_test4_codestart
dc_test4_bad8		=	_test4_bad8 - def_drivecodestart + dc_test4_codestart
	SHARED	dc_t4_testsp
	SHARED	dc_t4_testzp
	SHARED	dc_test4_codestart
	SHARED	dc_test4_codeend
	SHARED	dc_t4_start
	SHARED	dc_test4_bad1
	SHARED	dc_test4_bad2
	SHARED	dc_test4_good1
	SHARED	dc_test4_good2
	SHARED	dc_test4_good3
	SHARED	dc_test4_good4
	SHARED	dc_test4_good5
	SHARED	dc_test4_good6
	SHARED	dc_test4_bad3
	SHARED	dc_test4_bad4
	SHARED	dc_test4_good7
	SHARED	dc_test4_good8
	SHARED	dc_test4_good9
	SHARED	dc_test4_good10
	SHARED	dc_test4_bad5
	SHARED	dc_test4_bad6
	SHARED	dc_test4_bad7
	SHARED	dc_test4_bad8
;------------------------------------------------------------------------------
;---	Test5: SP + Txx + Pxx tests

dc_t5_testsp	=	$02ef
dc_t5_testzph	=	$0200
dc_t5_data1	=	$76
dc_t5_data2	=	$87
dc_t5_data3	=	$98

dc_test5_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t5_start
		ldy	#hi(dc_t5_testzph)
		tyzph
		ldy	#hi(dc_t5_testsp)
		tysph
		ldx	#lo(dc_t5_testsp)
		txs
		break	def_exitcode
		lda	#dc_t5_data1
		ldx	#dc_t5_data2
		ldy	#dc_t5_data3
		pha
		txa
		pha
		tya
		pha
		break	def_exitcode
		pla
		tax
		pla
		tay
		pla
		break	def_exitcode
	DEPHASE
dc_test5_codeend	=	* - def_offset

	SHARED	dc_test5_codestart
	SHARED	dc_test5_codeend
	SHARED	dc_t5_start
	SHARED	dc_t5_testsp
	SHARED	dc_t5_testzph
	SHARED	dc_t5_data1
	SHARED	dc_t5_data2
	SHARED	dc_t5_data3
;------------------------------------------------------------------------------
;---	Test6: SP test continue, Flags test

dc_test6_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t6_start
		lda	#%11111111
		pha
		plp
		break	def_exitcode
		lda	#%00000000
		pha
		plp
		break	def_exitcode
		lda	#$00
		php
		pla
		sta	dc_t6_data+0
		lda	#$01
		php
		pla
		sta	dc_t6_data+1
		lda	#$80
		php
		pla
		sta	dc_t6_data+2
		ldx	#$01
		php
		pla
		sta	dc_t6_data+3
		ldx	#$80
		php
		pla
		sta	dc_t6_data+4
		ldx	#$00
		php
		pla
		sta	dc_t6_data+5
		ldy	#$80
		php
		pla
		sta	dc_t6_data+6
		ldy	#$00
		php
		pla
		sta	dc_t6_data+7
		ldy	#$01
		php
		pla
		sta	dc_t6_data+8
		break	def_exitcode
dc_t6_data	BYT	1,2,3,4,5,6,7,8,9
	DEPHASE
dc_test6_codeend	=	* - def_offset

	SHARED	dc_test6_codestart
	SHARED	dc_test6_codeend
	SHARED	dc_t6_start
	SHARED	dc_t6_data
;------------------------------------------------------------------------------
;---	Test7: JMP / JSR / RTS / RTI test

dc_t7_sp	=	def_drivecodestart + $ef
dc_t7_zp	=	def_drivecodestart

dc_test7a_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t7a_start
		ldy	#hi(dc_t7_zp)
		tyzph
		ldy	#hi(dc_t7_sp)
		tysph
		ldx	#lo(dc_t7_sp)
		txs
		lda	#%00000000
		pha
		plp
		jmp	dc_t7a_test_1
		break	0
		break	0
		break	0
dc_t7a_test_1	break	0
		break	0
		break	0
		break	0
	DEPHASE
dc_test7a_codeend	=	* - def_offset

dc_test7b_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t7b_start
		lda	#$33
		ldx	#$44
		ldy	#$55
dc_t7b_test_1	jsr	dc_t7b_test_2
dc_t7b_test_3	break	0
		jmp	(dc_t7b_test_4)
		break	0
		break	0
		break	0
dc_t7b_test_6	break	0
		break	0
		break	0
		break	0
dc_t7b_test_2	break	0
		rts
		break	0
		break	0
		break	0
dc_t7b_test_4	ADR	dc_t7b_test_5
		break	0
		break	0
		break	0
dc_t7b_test_5	break	0
		lda	#hi(dc_t7b_test_6)
		pha
		lda	#lo(dc_t7b_test_6)
		pha
		lda	#%11111111
		pha
		rti
	DEPHASE
dc_test7b_codeend	=	* - def_offset

	SHARED	dc_t7_sp
	SHARED	dc_t7_zp
	SHARED	dc_test7a_codestart
	SHARED	dc_test7a_codeend
	SHARED	dc_t7a_start
	SHARED	dc_t7a_test_1
	SHARED	dc_test7b_codestart
	SHARED	dc_test7b_codeend
	SHARED	dc_t7b_start
	SHARED	dc_t7b_test_1
	SHARED	dc_t7b_test_2
	SHARED	dc_t7b_test_3
	SHARED	dc_t7b_test_4
	SHARED	dc_t7b_test_5
	SHARED	dc_t7b_test_6
;------------------------------------------------------------------------------
;---	Test8: Bxx, SEx, CLx tests

dc_test8_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t8_start
		lda	#%00000000
		pha
		plp
		beq	dc_t8_error
		bne	dc_t8_1
dc_t8_9		break	0
dc_t8_1		break	0
		bcs	dc_t8_error
		bcc	dc_t8_2
		break	0
dc_t8_2		break	0
		bvs	dc_t8_error
		bvc	dc_t8_3
		break	0
dc_t8_3		break	0
		bmi	dc_t8_error
		bpl	dc_t8_4
		break	0
dc_t8_4		break	0
		lda	#$00			;Set "Z"
		break	0
		bne	dc_t8_error
		beq	dc_t8_5
		break	0
dc_t8_5		break	0
		lda	#$80			;Set "N"
		break	0
		bpl	dc_t8_error
		bmi	dc_t8_6
		break	0
dc_t8_6		break	0
		sec
		break	0
		bcc	dc_t8_error
		bcs	dc_t8_7
		break	0
dc_t8_7		break	0
		clc
		break	0
		lda	#%01000000
		pha
		plp				;Set "V"
		break	0
		bvc	dc_t8_error
		bvs	dc_t8_8
		break	0
dc_t8_8		break	0
		clv
		break	0
		bvc	dc_t8_9
dc_t8_error	break	def_exitcode
	DEPHASE
dc_test8_codeend	=	* - def_offset

	SHARED	dc_test8_codestart
	SHARED	dc_test8_codeend
	SHARED	dc_t8_start
	SHARED	dc_t8_1
	SHARED	dc_t8_2
	SHARED	dc_t8_3
	SHARED	dc_t8_4
	SHARED	dc_t8_5
	SHARED	dc_t8_6
	SHARED	dc_t8_7
	SHARED	dc_t8_8
	SHARED	dc_t8_9
	SHARED	dc_t8_error
;------------------------------------------------------------------------------
;---	Test9: INX/INY/DEX/DEY + flags tests

dc_test9_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t9_start
		lda	#%00000000
		pha
		plp
		ldx	#%00000000
		stx	dc_t9_results+0
		php
		pla
		sta	dc_t9_results+1
		inx
		stx	dc_t9_results+2
		php
		pla
		sta	dc_t9_results+3
		dex
		stx	dc_t9_results+4
		php
		pla
		sta	dc_t9_results+5
		dex
		stx	dc_t9_results+6
		php
		pla
		sta	dc_t9_results+7

		ldy	#%00000000
		sty	dc_t9_results+8
		php
		pla
		sta	dc_t9_results+9
		iny
		sty	dc_t9_results+10
		php
		pla
		sta	dc_t9_results+11
		dey
		sty	dc_t9_results+12
		php
		pla
		sta	dc_t9_results+13
		dey
		sty	dc_t9_results+14
		php
		pla
		sta	dc_t9_results+15
		break	def_exitcode
dc_t9_results	BYT	$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc
		BYT	$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc
dc_t9_results_end
	DEPHASE
dc_test9_codeend	=	* - def_offset

	SHARED	dc_test9_codestart
	SHARED	dc_test9_codeend
	SHARED	dc_t9_start
	SHARED	dc_t9_results
	SHARED	dc_t9_results_end
;------------------------------------------------------------------------------
;---	Test10: ADC tests

dc_test10_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t10_start
		clc
		lda	#$7e
		sta	dc_t10_results+0
		adc	#$01
		sta	dc_t10_results+1
		php
		pla
		sta	dc_t10_results+2
		sec
		lda	#$7e
		sta	dc_t10_results+3
		adc	#$01
		sta	dc_t10_results+4
		php
		pla
		sta	dc_t10_results+5
		clc
		lda	#$fe
		sta	dc_t10_results+6
		adc	#$01
		sta	dc_t10_results+7
		php
		pla
		sta	dc_t10_results+8
		sec
		lda	#$fe
		sta	dc_t10_results+9
		adc	#$01
		sta	dc_t10_results+10
		php
		pla
		sta	dc_t10_results+11
		clc
		lda	#$80
		adc	#$80
		sta	dc_t10_results+12
		php
		pla
		sta	dc_t10_results+13
		break	def_exitcode
dc_t10_results	BYT	$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc
		BYT	$cc,$cc,$cc,$cc,$dd,$dd
dc_t10_results_end
	DEPHASE
dc_test10_codeend	=	* - def_offset

	SHARED	dc_test10_codestart
	SHARED	dc_test10_codeend
	SHARED	dc_t10_start
	SHARED	dc_t10_results
	SHARED	dc_t10_results_end
;------------------------------------------------------------------------------
;---	Test11: SBC tests

dc_test11_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t11_start
		sec
		lda	#$81
		sta	dc_t11_results+0
		sbc	#$01
		sta	dc_t11_results+1
		php
		pla
		sta	dc_t11_results+2
		clc
		lda	#$81
		sta	dc_t11_results+3
		sbc	#$01
		sta	dc_t11_results+4
		php
		pla
		sta	dc_t11_results+5
		sec
		lda	#$01
		sta	dc_t11_results+6
		sbc	#$01
		sta	dc_t11_results+7
		php
		pla
		sta	dc_t11_results+8
		clc
		lda	#$01
		sta	dc_t11_results+9
		sbc	#$01
		sta	dc_t11_results+10
		php
		pla
		sta	dc_t11_results+11
		sec
		lda	#$80
		sbc	#$80
		sta	dc_t11_results+12
		php
		pla
		sta	dc_t11_results+13
		break	def_exitcode
dc_t11_results	BYT	$cc,$cc,$cc,$cc,$cc,$cc,$cc,$cc
		BYT	$cc,$cc,$cc,$cc,$dd,$dd
dc_t11_results_end
	DEPHASE
dc_test11_codeend	=	* - def_offset

	SHARED	dc_test11_codestart
	SHARED	dc_test11_codeend
	SHARED	dc_t11_start
	SHARED	dc_t11_results
	SHARED	dc_t11_results_end
;------------------------------------------------------------------------------
;---	Test12: CMP tests

dc_test12_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t12_start
		lda	#%00000000
		pha
		plp
		lda	#$7f
		cmp	#$7f
		php
		pla
		sta	dc_t12_results+0
		lda	#$7f
		cmp	#$7e
		php
		pla
		sta	dc_t12_results+1
		lda	#$7f
		cmp	#$80
		php
		pla
		sta	dc_t12_results+2
		lda	#$80
		cmp	#$80
		php
		pla
		sta	dc_t12_results+3
		lda	#$80
		cmp	#$7f
		php
		pla
		sta	dc_t12_results+4
		lda	#$80
		cmp	#$81
		php
		pla
		sta	dc_t12_results+5
		break	def_exitcode
dc_t12_results	BYT	$cc,$cc,$cc,$cc,$cc,$cc
dc_t12_results_end
	DEPHASE
dc_test12_codeend	=	* - def_offset

	SHARED	dc_test12_codestart
	SHARED	dc_test12_codeend
	SHARED	dc_t12_start
	SHARED	dc_t12_results
	SHARED	dc_t12_results_end
;------------------------------------------------------------------------------
;---	Test13: INC/DEC $zp / $uiop tests

dc_test13_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t13_start
		lda	#%00000000
		pha
		plp
		ldy	#hi(def_drivecodestart)
		tyzph
		tysph
		ldx	#$ef
		txs
		inc	dc_t13_results+0
		php
		pla
		sta	dc_t13_resrs+0
		dec	dc_t13_results+1
		php
		pla
		sta	dc_t13_resrs+1

		inc	lo(dc_t13_results+2)
		php
		pla
		sta	dc_t13_resrs+2
		dec	lo(dc_t13_results+3)
		php
		pla
		sta	dc_t13_resrs+3
		break	def_exitcode

dc_t13_results	BYT	$00
		BYT	$01
		BYT	$ff
		BYT	$00
dc_t13_resrs	BYT	$ee,$ee,$ee,$ee
dc_t13_results_end
	DEPHASE
dc_test13_codeend	=	* - def_offset

	SHARED	dc_test13_codestart
	SHARED	dc_test13_codeend
	SHARED	dc_t13_start
	SHARED	dc_t13_results
	SHARED	dc_t13_results_end
;------------------------------------------------------------------------------
;---	Test14: ASL/LSR/ROL/ROR $zp / $uiop tests

dc_test14_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t14_start
		asl	dc_t14_results+0
		php
		pla
		sta	dc_t14_resrs+0
		rol	dc_t14_results+1
		php
		pla
		sta	dc_t14_resrs+1
		lsr	dc_t14_results+2
		php
		pla
		sta	dc_t14_resrs+2
		ror	dc_t14_results+3
		php
		pla
		sta	dc_t14_resrs+3
		asl	lo(dc_t14_results+4)
		php
		pla
		sta	dc_t14_resrs+4
		rol	lo(dc_t14_results+5)
		php
		pla
		sta	dc_t14_resrs+5
		lsr	lo(dc_t14_results+6)
		php
		pla
		sta	dc_t14_resrs+6
		ror	lo(dc_t14_results+7)
		php
		pla
		sta	dc_t14_resrs+7
		lda	#%10101010
		asl	a
		sta	lo(dc_t14_results+8)
		php
		tax
		pla
		sta	dc_t14_resrs+8
		txa
		rol	a
		sta	lo(dc_t14_results+9)
		php
		tax
		pla
		sta	dc_t14_resrs+9
		lda	#%00000001
		lsr	a
		sta	lo(dc_t14_results+10)
		php
		tax
		pla
		sta	dc_t14_resrs+10
		txa
		ror	a
		sta	lo(dc_t14_results+11)
		php
		tax
		pla
		sta	dc_t14_resrs+11
		break	def_exitcode
dc_t14_results	BYT	%10000101
		BYT	%01010001
		BYT	%10100001
		BYT	%10001010
		BYT	%10000111
		BYT	%01110001
		BYT	%00000001
		BYT	%10001110
		BYT	$ff,$ff,$ff,$ff
dc_t14_resrs	BYT	$ee,$ee,$ee,$ee,$ee,$ee,$ee,$ee
		BYT	$ee,$ee,$ee,$ee
dc_t14_results_end
	DEPHASE
dc_test14_codeend	=	* - def_offset

	SHARED	dc_test14_codestart
	SHARED	dc_test14_codeend
	SHARED	dc_t14_start
	SHARED	dc_t14_results
	SHARED	dc_t14_results_end
;------------------------------------------------------------------------------
;---	Test15: ORA test

dc_test15_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t15_start
		lda	#%00000000
		pha
		plp
		lda	#%10100111
		and	#%11111100
		sta	dc_t15_results+0
		pha
		php
		pla
		sta	dc_t15_sregs+0
		pla
		and	#%00001111
		sta	dc_t15_results+1
		pha
		php
		pla
		sta	dc_t15_sregs+1
		pla
		and	#%11110011
		sta	dc_t15_results+2
		php
		pla
		sta	dc_t15_sregs+2
		break	def_exitcode
dc_t15_results	BYT	%11110000
		BYT	%11110000
		BYT	%11110000
dc_t15_sregs	BYT	$55,$55,$55
dc_t15_results_end
	DEPHASE
dc_test15_codeend	=	* - def_offset

	SHARED	dc_test15_codestart
	SHARED	dc_test15_codeend
	SHARED	dc_t15_start
	SHARED	dc_t15_results
	SHARED	dc_t15_results_end
;------------------------------------------------------------------------------
;---	Test16: AND test

dc_test16_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t16_start
		lda	#%00000000
		pha
		plp
		lda	#%00011000
		ora	#%00000011
		sta	dc_t16_results+0
		pha
		php
		pla
		sta	dc_t16_sregs+0
		pla
		ora	#%11000011
		sta	dc_t16_results+1
		pha
		php
		pla
		sta	dc_t16_sregs+1
		pla
		ora	#%00100100
		sta	dc_t16_results+2
		php
		pla
		sta	dc_t16_sregs+2
		break	def_exitcode
dc_t16_results	BYT	%11110000
		BYT	%11110000
		BYT	%11110000
dc_t16_sregs	BYT	$55,$55,$55
dc_t16_results_end
	DEPHASE
dc_test16_codeend	=	* - def_offset

	SHARED	dc_test16_codestart
	SHARED	dc_test16_codeend
	SHARED	dc_t16_start
	SHARED	dc_t16_results
	SHARED	dc_t16_results_end
;------------------------------------------------------------------------------
;---	Test17: EOR test

dc_test17_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t17_start
		lda	#%00000000
		pha
		plp
		lda	#%00011000
		eor	#%00001011
		sta	dc_t17_results+0
		pha
		php
		pla
		sta	dc_t17_sregs+0
		pla
		eor	#%11010000
		sta	dc_t17_results+1
		pha
		php
		pla
		sta	dc_t17_sregs+1
		pla
		eor	#%11000011
		sta	dc_t17_results+2
		php
		pla
		sta	dc_t17_sregs+2
		break	def_exitcode
dc_t17_results	BYT	%11110000
		BYT	%11110000
		BYT	%11110000
dc_t17_sregs	BYT	$55,$55,$55
dc_t17_results_end
	DEPHASE
dc_test17_codeend	=	* - def_offset

	SHARED	dc_test17_codestart
	SHARED	dc_test17_codeend
	SHARED	dc_t17_start
	SHARED	dc_t17_results
	SHARED	dc_t17_results_end
;------------------------------------------------------------------------------
;---	Test18: LDA $uiop,X/Y / STA $uiop,X/Y tests

dc_test18_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t18_start
		ldx	#$$source1_end - $$source1 - 1
		ldy	#0
$$copycyc	lda	$$source1,x
		sta	dc_t18_dest1+2,x
		lda	$$source2,y
		sta	dc_t18_dest2+2,y
		iny
		dex
		bpl	$$copycyc
		break	def_exitcode
$$source1	BYT	$11,$22,$33,$44,$55,$66,$77,$88
$$source1_end
$$source2	BYT	$12,$34,$56,$78,$9a,$bc,$de,$f0

dc_t18_results
dc_t18_dest1	BYT	$ff,$ff
		BYT	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		BYT	$ff,$ff
dc_t18_dest2	BYT	$55,$55
		BYT	$55,$55,$55,$55,$aa,$aa,$aa,$aa
		BYT	$aa,$aa
dc_t18_results_end
	DEPHASE
dc_test18_codeend	=	* - def_offset

	SHARED	dc_test18_codestart
	SHARED	dc_test18_codeend
	SHARED	dc_t18_start
	SHARED	dc_t18_results
	SHARED	dc_t18_results_end
;------------------------------------------------------------------------------
;---	Test19: LDA+STA $zp,X LDX/STX $zp,Y, LDY/STY $zp,X tests

dc_test19_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t19_start
		ldy	#hi(dc_t19_zpaddress)
		tyzph
		ldx	#dc_t19_source_end - dc_t19_source - 1 - 2
		ldy	#0
$$copycyc	lda	dc_t19_source,x
		sta	dc_t19_target+2,x
		dex
		bpl	$$copycyc
		ldy	#dc_t19_source_end-2-dc_t19_source
		ldx	dc_t19_source,y
		ldy	#dc_t19_target_end-2-dc_t19_target
		stx	lo(dc_t19_target),y

		ldx	#dc_t19_source_end - 1 - dc_t19_source
		ldy	dc_t19_source,x
		ldx	#dc_t19_target_end - 1 - dc_t19_target
		sty	lo(dc_t19_target),x
		break	def_exitcode
dc_t19_zpaddress
	DEPHASE
	PHASE	dc_t19_zpaddress & $ff
dc_t19_source	BYT	$11,$22,$33,$44,$55,$66,$77,$88
		BYT	$48,$84
dc_t19_source_end
dc_t19_target	BYT	$a5,$a5
		BYT	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		BYT	$5a,$5a,$ff,$ff
dc_t19_target_end
	DEPHASE

dc_t19_results		=	dc_t19_zpaddress & $ff00 + dc_t19_target
dc_t19_results_end	=	dc_t19_zpaddress & $ff00 + dc_t19_target_end

dc_test19_codeend	=	* - def_offset

	SHARED	dc_test19_codestart
	SHARED	dc_test19_codeend
	SHARED	dc_t19_start
	SHARED	dc_t19_results
	SHARED	dc_t19_results_end
;------------------------------------------------------------------------------
;---	Test20: LDA+STA ($zp),Y test

dc_test20_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t20_start
		ldy	#hi(dc_t20_zpaddress)
		tyzph
		lda	#lo($$source)
		sta	dc_t20_z_src+0
		lda	#hi($$source)
		sta	dc_t20_z_src+1
		lda	#lo(dc_t20_results+1)
		sta	dc_t20_z_dest+0
		lda	#hi(dc_t20_results+1)
		sta	dc_t20_z_dest+1
		ldy	#0
$$copycyc	lda	(dc_t20_z_src),y
		iny
		sta	(dc_t20_z_dest),y
		cpy	#$$source_end - $$source
		bne	$$copycyc
		break	def_exitcode

$$source	BYT	$99,$88,$77,$66,$55,$44,$33,$22
$$source_end

dc_t20_results	BYT	$ee,$ee
		BYT	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		BYT	$dd,$dd
dc_t20_results_end
dc_t20_zpaddress
	DEPHASE
	PHASE	dc_t20_zpaddress & $ff
dc_t20_z_src	ADR	$0000
dc_t20_z_dest	ADR	$0000
	DEPHASE
dc_test20_codeend	=	* - def_offset

	SHARED	dc_test20_codestart
	SHARED	dc_test20_codeend
	SHARED	dc_t20_start
	SHARED	dc_t20_results
	SHARED	dc_t20_results_end
;------------------------------------------------------------------------------
;---	Test21: LDA+STA ($zp,X) test

dc_test21_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t21_start
		ldy	#hi(dc_t21_zpaddress)
		tyzph
		lda	#lo($$source)
		sta	dc_t21_z_src+0
		lda	#hi($$source)
		sta	dc_t21_z_src+1
		lda	#lo(dc_t21_results+2)
		sta	dc_t21_z_dest+0
		lda	#hi(dc_t21_results+2)
		sta	dc_t21_z_dest+1
		ldy	#$$source_end - $$source - 1
$$copycyc	ldx	#0
		lda	(dc_t21_z_ptrs,x)
		ldx	#2
		sta	(dc_t21_z_ptrs,x)
		inc	dc_t21_z_src+0
		inc	dc_t21_z_dest+0
		dey
		bpl	$$copycyc
		break	def_exitcode

$$source	BYT	$ee,$11,$dd,$22,$cc,$33,$bb,$44
$$source_end

dc_t21_results	BYT	$99,$99
		BYT	$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
		BYT	$88,$88
dc_t21_results_end
dc_t21_zpaddress
	DEPHASE
	PHASE	dc_t21_zpaddress & $ff
dc_t21_z_ptrs
dc_t21_z_src	ADR	$0000
dc_t21_z_dest	ADR	$0000
	DEPHASE
dc_test21_codeend	=	* - def_offset

	SHARED	dc_test21_codestart
	SHARED	dc_test21_codeend
	SHARED	dc_t21_start
	SHARED	dc_t21_results
	SHARED	dc_t21_results_end
;------------------------------------------------------------------------------
;---	Test22: BIT $zp / $uiop tests

dc_test22_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t22_start
		ldsph	hi(def_drivecodestart)
		ldx	#$ff
		txs
		ldzph	hi(def_drivecodestart)
		lda	#%00000000
		pha
		plp
		lda	#%00011111
		bit	$$tdata+0
		php
		pla
		sta	dc_t22_results+0
		lda	#%00011111
		bit	lo($$tdata+0)
		php
		pla
		sta	dc_t22_results+1

		lda	#%00010111
		bit	$$tdata+1
		php
		pla
		sta	dc_t22_results+2
		lda	#%00010111
		bit	lo($$tdata+1)
		php
		pla
		sta	dc_t22_results+3

		lda	#%00011111
		bit	$$tdata+2
		php
		pla
		sta	dc_t22_results+4
		lda	#%00011111
		bit	lo($$tdata+2)
		php
		pla
		sta	dc_t22_results+5
		break	def_exitcode
$$tdata		BYT	%00001000
		BYT	%01001000
		BYT	%11000000
dc_t22_results
		BYT	$ff,$ff,$ff,$ff,$ff,$ff
dc_t22_results_end
	DEPHASE
dc_test22_codeend	=	* - def_offset

	SHARED	dc_test22_codestart
	SHARED	dc_test22_codeend
	SHARED	dc_t22_start
	SHARED	dc_t22_results
	SHARED	dc_t22_results_end
;------------------------------------------------------------------------------
;---	Test23: UINDB / UDEDB test

;dc_t23_sp	=	def_drivecodestart + $ef
;dc_t23_zp	=	def_drivecodestart

dc_test23_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t23_start
		ldx	#$55
		ldy	#1
		jmp	dc_t23_p1
		break	0
		break	0
		break	0
		break	0
dc_t23_p1	break	0
		nop
		nop
		nop
		uindb	dc_t23_p1
dc_t23_p2	break	0
		ldx	#$66
		ldy	#1
dc_t23_p3	break	0
		nop
		nop
		nop
		udedb	dc_t23_p3
dc_t23_p4	break	0
	DEPHASE
dc_test23_codeend	=	* - def_offset

	SHARED	dc_test23_codestart
	SHARED	dc_test23_codeend
	SHARED	dc_t23_start
	SHARED	dc_t23_p1
	SHARED	dc_t23_p2
	SHARED	dc_t23_p3
	SHARED	dc_t23_p4
;------------------------------------------------------------------------------
;---	Test24: Convert byte value to ASCII decimal chars + decimal digits
;---	  with converter peripheral

dc_test24_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t24_start
		ldsph	hi(def_drivecodestart)
		ldy	#0

		lda	#0
		sta	vcpu_bin2ascii
		jsr	dc_t24_storeresult
		lda	#9
		sta	vcpu_bin2ascii
		jsr	dc_t24_storeresult
		lda	#10
		sta	vcpu_bin2ascii
		jsr	dc_t24_storeresult
		lda	#99
		sta	vcpu_bin2ascii
		jsr	dc_t24_storeresult
		lda	#100
		sta	vcpu_bin2ascii
		jsr	dc_t24_storeresult
		lda	#255
		sta	vcpu_bin2ascii
		jsr	dc_t24_storeresult
		lda	#0
		sta	vcpu_bin2decimal
		jsr	dc_t24_storeresult
		lda	#9
		sta	vcpu_bin2decimal
		jsr	dc_t24_storeresult
		lda	#10
		sta	vcpu_bin2decimal
		jsr	dc_t24_storeresult
		lda	#99
		sta	vcpu_bin2decimal
		jsr	dc_t24_storeresult
		lda	#100
		sta	vcpu_bin2decimal
		jsr	dc_t24_storeresult
		lda	#255
		sta	vcpu_bin2decimal
		jsr	dc_t24_storeresult
		break	def_exitcode

dc_t24_storeresult
		lda	vcpu_bin2resulth
		sta	dc_t24_results,y
		iny
		lda	vcpu_bin2resultm
		sta	dc_t24_results,y
		iny
		lda	vcpu_bin2resultl
		sta	dc_t24_results,y
		iny
		rts

dc_t24_results	BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
		BYT	0,0,0
dc_t24_results_end
	DEPHASE
dc_test24_codeend	=	* - def_offset

	SHARED	dc_test24_codestart
	SHARED	dc_test24_codeend
	SHARED	dc_t24_start
	SHARED	dc_t24_results
	SHARED	dc_t24_results_end
;------------------------------------------------------------------------------
;---	Test25: Memory boundary tests

dc_test25_codestart	=	* - def_offset
	PHASE	def_drivecodestart
dc_t25_start
		ldzph	hi(dc_t25_zistr)
		ldy	#lo(dc_t25_zistr)
		ldx	#dc_t25_zistr_e-dc_t25_zistr
		break	vcpu_syscall_directcommand_mem
		cmp	#0			;OK?
		beq	$$okay
$$exit		break	vcpu_syscall_exit_remain
$$okay		cpx	#5			;Answer length: 5 BYTE?
		bcc	$$exit			;If less, maybe older firmware, exit
		ldx	vcpu_errorbuffer+1	;Command-channel length
		stx	dc_t25_p8+1
		stx	dc_t25_p9+1
		dex
		stx	dc_t25_p7+1
		ldx	vcpu_errorbuffer+2	;Error-channel length
		stx	dc_t25_p11+1
		stx	dc_t25_p12+1
		dex
		stx	dc_t25_p10+1

		lda	vcpu_memiosize		;I/O + Memory size
		and	#%00011111		;Memory size remain
		cmp	vcpu_errorbuffer+3	;Equal?
		bne	$$exit			;If not, error
		sta	dc_t25_p2+2
		sta	dc_t25_p3+2
		tax
		dex
		stx	dc_t25_p1+2

		lda	vcpu_memiosize		;I/O + Memory size
		rol	a
		rol	a
		rol	a
		rol	a			;B765 -> B210
		and	#%00000111		;I/O ~size remain (3 = $10)
		tax
		lda	dc_t25_iosizes,x	;2,4,8,16,32,64,128,lo(256-1)
		cmp	vcpu_errorbuffer+4
		bcc	$$exit			;If not less or equal, error, exit
		ldx	vcpu_errorbuffer+4	;I/O area last valid address
		stx	dc_t25_p4+1
		inx
		stx	dc_t25_p5+1
		stx	dc_t25_p6+1

dc_t25_p1	lda	$ffff			;<- previously set address: read last valid memory
dc_t25_p2	lda	$ff00			;<- previously set address: read first invalid memory
dc_t25_p3	sta	$ff00			;<- previously set address: write first invalid memory
dc_t25_p4	lda	vcpu_iobase+$ff		;<- previously set address: read last valid I/O
dc_t25_p5	lda	vcpu_iobase+$ff		;<- previously set address: read first invalid I/O
dc_t25_p6	sta	vcpu_iobase+$ff		;<- previously set address: write first invalid I/O
dc_t25_p7	lda	vcpu_commandbuffer+$ff	;<- previously set address: read last valid command buffer byte
dc_t25_p8	lda	vcpu_commandbuffer+$ff	;<- previously set address: read first invalid command buffer byte
dc_t25_p9	sta	vcpu_commandbuffer+$ff	;<- previously set address: write first invalid command buffer byte
dc_t25_p10	lda	vcpu_errorbuffer+$ff	;<- previously set address: read last valid error buffer byte
dc_t25_p11	lda	vcpu_errorbuffer+$ff	;<- previously set address: read first invalid error buffer byte
dc_t25_p12	sta	vcpu_errorbuffer+$ff	;<- previously set address: write first invalid error buffer byte
dc_t25_p13	break	def_exitcode

dc_t25_iosizes	BYT	2,4,8,16,32,64,128,lo(256-1)
dc_t25_zistr	BYT	"ZI"
dc_t25_zistr_e

	DEPHASE
dc_test25_codeend	=	* - def_offset

	SHARED	dc_test25_codestart
	SHARED	dc_test25_codeend
	SHARED	dc_t25_start
	SHARED	dc_t25_p1
	SHARED	dc_t25_p2
	SHARED	dc_t25_p3
	SHARED	dc_t25_p4
	SHARED	dc_t25_p5
	SHARED	dc_t25_p6
	SHARED	dc_t25_p7
	SHARED	dc_t25_p8
	SHARED	dc_t25_p9
	SHARED	dc_t25_p10
	SHARED	dc_t25_p11
	SHARED	dc_t25_p12
	SHARED	dc_t25_p13
;------------------------------------------------------------------------------
;---	Test26: VCPU R2 USER1 / USER2 / USERR
;---			TYXxx / TxxYX commands tests

dc_test26_codestart	=	* - def_offset
dc_t26_stack		=	def_drivecodestart + $ff
	PHASE	def_drivecodestart
dc_t26_start
		ldsph	hi(dc_t26_stack)
		ldx	#lo(dc_t26_stack)
		txs
		ldx	#$00
		ldy	#$00
		jsr	dc_t26_setallvect
		break	def_exitcode
		ldx	#$ff
		lda	vcpu_memiosize
		and	#%00011111
		tay
		dey
		jsr	dc_t26_setallvect
		break	def_exitcode
		inx
		iny
		jsr	dc_t26_setallvect

		ldx	#lo(dc_t26_sub1)
		ldy	#hi(dc_t26_sub1)
		tyxu1				;USER1 vector set (U1R)
		ldx	#lo(dc_t26_sub2)
		ldy	#hi(dc_t26_sub2)
		tyxu2				;USER2 vector set (U2R)
		break	def_exitcode

		lda	#$55
dc_t26_call1	user1				;Call USER1
dc_t26_ret1	break	def_exitcode

		lda	#$5a
dc_t26_call2	user2				;Call USER2
dc_t26_ret2	break	def_exitcode

		ldx	#$ff
		ldy	#$ff
		trryx				;Read RR
dc_t26_crr	break	def_exitcode

		ldx	#$ff
		ldy	#$ff
		tu1yx				;Read U1R
dc_t26_cu1	break	def_exitcode

		ldx	#$ff
		ldy	#$ff
		tu2yx				;Read U2R
dc_t26_cu2	break	def_exitcode

		pshrr				;Push RR to stack
		ldx	#$01
		ldy	#$01
		tyxrr
		pla
		tax
		pla
		tay
		pha
		txa
		pha
dc_t26_s1	break	def_exitcode

		ldx	#$dd
		ldy	#$ee
		pulrr				;Pull RR from stack
		trryx
dc_t26_s2	break	def_exitcode

		break	0
		break	0
		break	0
dc_t26_sub1	break	def_exitcode
		asl	a
		userr				;RETURN from USER call
		break	0
		break	0
		break	0
dc_t26_sub2	break	def_exitcode
		eor	#%11111111
		userr				;RETURN from USER call
		break	0
		break	0
		break	0

dc_t26_setallvect
dc_t26_setrr	tyxrr				;Set RR
dc_t26_setu1	tyxu1				;Set U1R
dc_t26_setu2	tyxu2				;Set U2R
		rts

	DEPHASE
dc_test26_codeend	=	* - def_offset

	SHARED	dc_test26_codestart
	SHARED	dc_test26_codeend
	SHARED	dc_t26_stack
	SHARED	dc_t26_start
	SHARED	dc_t26_call1
	SHARED	dc_t26_call2
	SHARED	dc_t26_ret1
	SHARED	dc_t26_ret2
	SHARED	dc_t26_sub1
	SHARED	dc_t26_sub2
	SHARED	dc_t26_setrr
	SHARED	dc_t26_setu1
	SHARED	dc_t26_setu2
	SHARED	dc_t26_crr
	SHARED	dc_t26_cu1
	SHARED	dc_t26_cu2
	SHARED	dc_t26_s1
	SHARED	dc_t26_s2
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	SHARED	def_exitcode
;------------------------------------------------------------------------------
