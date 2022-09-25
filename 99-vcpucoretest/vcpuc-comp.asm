;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.09.17.+ by BSZ
;---	VCPU core test codes - computer side
;------------------------------------------------------------------------------
phaseaddrlist	ADR	cc_t0			;SysCall test
		ADR	cc_t1			;Illegal opcode
		ADR	cc_t2			;LDA/X/Y #$gh tests
		ADR	cc_t3			;STA $xxxx / STX $yyyy / STY $zzzz tests
		ADR	cc_t4			;SPH/ZPH set test
		ADR	cc_t5			;SP + Txx + Pxx tests
		ADR	cc_t6			;SP test continue, Flags test
		ADR	cc_t7			;JMP / JSR / RTS / RTI test
		ADR	cc_t8			;Bxx, SEx, CLx tests
		ADR	cc_t9			;INX/INY/DEX/DEY + flags tests
		ADR	cc_t10			;ADC tests
		ADR	cc_t11			;SBC tests
		ADR	cc_t12			;CMP tests
		ADR	cc_t13			;INC/DEC $zp / $uiop tests
		ADR	cc_t14			;ASL/LSR/ROL/ROR $zp / $uiop tests
		ADR	cc_t15			;ORA test
		ADR	cc_t16			;AND test
		ADR	cc_t17			;EOR test
		ADR	cc_t18			;LDA $uiop,X/Y / STA $uiop,X/Y tests
		ADR	cc_t19			;LDA+STA $zp,X LDX/STX $zp,Y, LDY/STY $zp,X tests
		ADR	cc_t20			;LDA+STA ($zp),Y test
		ADR	cc_t21			;LDA+STA ($zp,X) test
		ADR	cc_t22			;BIT $zp / $uiop tests
		ADR	cc_t23			;UINDB / UDEDB test
		ADR	cc_t24			;ATBCD: Convert A register to ASCII decimal chars
		ADR	$0000
;------------------------------------------------------------------------------
;---	Test0: SysCall test

cc_t0		BYT	def_job_download
		ADR	dc_test0_codeend - dc_test0_codestart		;BYTEno
		ADR	dc_test0_codestart				;Start offset
		ADR	dc_t0_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t0_start					;Drive code start address
		BYT	def_job_checkstatus
		ADR	$$statusdata
		BYT	def_job_readyexit

$$statusdata	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,def_exitcode	;COMMAND
		BYT	$ff,$00			;LASTOPCODE
;------------------------------------------------------------------------------
;---	Test1: Illegal opcode

cc_t1		BYT	def_job_download
		ADR	dc_test1_codeend - dc_test1_codestart		;BYTEno
		ADR	dc_test1_codestart				;Start offset
		ADR	dc_t1_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t1_start					;Drive code start address
		BYT	def_job_checkstatus
		ADR	$$statusdata
		BYT	def_job_readyexit

$$statusdata	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_error_hangup	;INTERRUPT
		BYT	$00,$00			;COMMAND
		BYT	$ff,$fc			;LASTOPCODE
;------------------------------------------------------------------------------
;---	Test2: LDA/X/Y #$gh tests

cc_t2		BYT	def_job_download
		ADR	dc_test2_codeend - dc_test2_codestart		;BYTEno
		ADR	dc_test2_codestart				;Start offset
		ADR	dc_t2_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t2_start					;Drive code start address
		BYT	def_job_checkstatus
		ADR	$$statusdata
		BYT	def_job_readyexit

$$statusdata	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$ff,dc_t2_data1		;A
		BYT	$ff,dc_t2_data2		;X
		BYT	$ff,dc_t2_data3		;Y
		BYT	$00,$00			;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,def_exitcode	;COMMAND
		BYT	$00,$00			;LASTOPCODE
;------------------------------------------------------------------------------
;---	Test3: STA $xxxx / STX $yyyy / STY $zzzz tests

cc_t3		BYT	def_job_download
		ADR	dc_test3_codeend - dc_test3_codestart		;BYTEno
		ADR	dc_test3_codestart				;Start offset
		ADR	dc_t3_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t3_start					;Drive code start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory
		ADR	3						;BYTEno
		ADR	dc_t3_tstbs					;Drive start address
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	dc_t3_data1
		BYT	dc_t3_data2
		BYT	dc_t3_data3
;------------------------------------------------------------------------------
;---	Test4: SPH/ZPH set test

cc_t4		BYT	def_job_setjob
		ADR	$$setdata
		BYT	def_job_download
		ADR	dc_test4_codeend - dc_test4_codestart		;BYTEno
		ADR	dc_test4_codestart				;Start offset
		ADR	dc_t4_start					;Drive start address
		BYT	def_job_setexecute
		BYT	9						;ADDRLO,ADDRHI,A,X,Y,SR,SP,SPH,ZPH
		ADR	$$execdata
		BYT	def_job_checkstatus
		ADR	$$statusdata1
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata2
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata2
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata3
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata4
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata5
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata5
		BYT	def_job_readyexit

$$setdata	ldx	_vcpubufferno			;Buffer size: 6: $0600..$FFFF Error
		stx	_drivecodes + dc_test4_bad1+1
		stx	_drivecodes + dc_test4_bad2+1
		stx	_drivecodes + dc_test4_bad3+2
		stx	_drivecodes + dc_test4_bad4+2
		dex					;$0000..$05FF: Ok
		stx	_drivecodes + dc_test4_good1+1
		stx	_drivecodes + dc_test4_good2+1
		stx	_drivecodes + dc_test4_good5+2
		stx	_drivecodes + dc_test4_good6+2
		stx	$$statusdata3_s+1
		stx	$$statusdata3_z+1
		dex
		stx	_drivecodes + dc_test4_good3+1
		stx	$$statusdata4_s+1
		dex
		stx	_drivecodes + dc_test4_good4+1
		stx	$$statusdata4_z+1
		rts

$$execdata	ADR	dc_t4_start							;ADDRLO,ADDRHI
		BYT	0,0,0,%00000000,$ff,(dc_t4_testsp >> 8),(dc_t4_testzp >> 8)	;A,X,Y,SR,SP,SPH,ZPH

$$statusdata1	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$00,$00			;SP
		BYT	$ff,(dc_t4_testsp >> 8)	;SPH
		BYT	$ff,(dc_t4_testzp >> 8)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT	$01: normal exit
		BYT	$00,$00			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata2	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$00,$00			;SP
		BYT	$ff,(dc_t4_testsp >> 8)	;SPH
		BYT	$ff,(dc_t4_testzp >> 8)	;ZPH
		BYT	$ff,vcpu_error_address	;INTERRUPT	$40: address error
		BYT	$00,$00			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata3	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$00,$00			;SP
$$statusdata3_s	BYT	$ff,$ff			;SPH	<- Modified!
$$statusdata3_z	BYT	$ff,$ff			;ZPH	<- Modified!
		BYT	$ff,vcpu_functioncall	;INTERRUPT	$01: Function Call
		BYT	$ff,def_exitcode	;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata4	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$00,$00			;SP
$$statusdata4_s	BYT	$ff,$ff			;SPH	<- Modified!
$$statusdata4_z	BYT	$ff,$ff			;ZPH	<- Modified!
		BYT	$ff,vcpu_functioncall	;INTERRUPT	$01: Function Call
		BYT	$ff,def_exitcode	;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata5	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_error_rwaddr	;INTERRUPT	$02: rwaddr error
		BYT	$00,$00			;COMMAND
		BYT	$00,$00			;LASTOPCODE
;------------------------------------------------------------------------------
;---	Test5: SP + Txx + Pxx tests

cc_t5		BYT	def_job_download
		ADR	dc_test5_codeend - dc_test5_codestart		;BYTEno
		ADR	dc_test5_codestart				;Start offset
		ADR	dc_t5_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t5_start					;Drive start address
		BYT	def_job_checkstatus
		ADR	$$statusdata1
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata2
		BYT	def_job_initpointer
		BYT	def_job_readmemory
		ADR	3
		ADR	dc_t5_testsp-3+1		;3 BYTEs to STACK, SP post-decrement (+1)
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata3
		BYT	def_job_readyexit

$$statusdata1	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$ff,lo(dc_t5_testsp)	;SP
		BYT	$ff,hi(dc_t5_testsp)	;SPH
		BYT	$ff,hi(dc_t5_testzph)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,def_exitcode	;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata2	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$00,$00			;SR
		BYT	$ff,lo(dc_t5_testsp-3)	;SP
		BYT	$ff,hi(dc_t5_testsp-3)	;SPH
		BYT	$ff,hi(dc_t5_testzph)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,def_exitcode	;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$checkdata	BYT	dc_t5_data3
		BYT	dc_t5_data2
		BYT	dc_t5_data1

$$statusdata3	BYT	$00,$00,$00,$00		;PC LO+HI
		BYT	$ff,dc_t5_data1		;A
		BYT	$ff,dc_t5_data3		;X
		BYT	$ff,dc_t5_data2		;Y
		BYT	$00,$00			;SR
		BYT	$ff,lo(dc_t5_testsp)	;SP
		BYT	$ff,hi(dc_t5_testsp)	;SPH
		BYT	$ff,hi(dc_t5_testzph)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,def_exitcode	;COMMAND
		BYT	$00,$00			;LASTOPCODE
;------------------------------------------------------------------------------
;---	Test6: SP test continue, Flags test

cc_t6		BYT	def_job_download
		ADR	dc_test6_codeend - dc_test6_codestart		;BYTEno
		ADR	dc_test6_codestart				;Start offset
		ADR	dc_t6_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t6_start					;Drive start address
		BYT	def_job_checkvcpusr
		BYT	%11110111					;Decimal bit clear
		BYT	def_job_contexecute
		BYT	def_job_checkvcpusr
		BYT	%00110000					;Decimal bit clear
		BYT	def_job_contexecute
		BYT	def_job_initpointer
		BYT	def_job_readmemory
		ADR	9
		ADR	dc_t6_data
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	%00110010, %00110000, %10110000
		BYT	%00110000, %10110000, %00110010
		BYT	%10110000, %00110010, %00110000
;------------------------------------------------------------------------------
;---	Test7: JMP / JSR / RTS / RTI test

cc_t7		BYT	def_job_download
		ADR	dc_test7a_codeend - dc_test7a_codestart		;BYTEno
		ADR	dc_test7a_codestart				;Start offset
		ADR	dc_t7a_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t7a_start					;Drive start address
		BYT	def_job_checkstatus
		ADR	$$statusdata1
		BYT	def_job_download
		ADR	dc_test7b_codeend - dc_test7b_codestart		;BYTEno
		ADR	dc_test7b_codestart				;Start offset
		ADR	dc_t7b_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t7b_start					;Drive start address
		BYT	def_job_checkstatus				;Check address
		ADR	$$statusdata2
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check SP
		ADR	2
		ADR	dc_t7_sp-2+1					;2 BYTEs to STACK, SP post-decrement (+1)
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_contexecute				;Start "RTS"
		BYT	def_job_checkstatus				;Check address
		ADR	$$statusdata3
		BYT	def_job_contexecute				;Start "JMP ()"
		BYT	def_job_checkstatus				;Check address
		ADR	$$statusdata4
		BYT	def_job_contexecute				;Start "RTI"
		BYT	def_job_checkstatus				;Check address
		ADR	$$statusdata5
		BYT	def_job_readyexit

$$statusdata1	BYT	$ff,lo(dc_t7a_test_1+2)	;PC LO
		BYT	$ff,hi(dc_t7a_test_1+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$ff,%00110000		;SR
		BYT	$ff,lo(dc_t7_sp)	;SP
		BYT	$ff,hi(dc_t7_sp)	;SPH
		BYT	$ff,hi(dc_t7_zp)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata2	BYT	$ff,lo(dc_t7b_test_2+2)	;PC LO
		BYT	$ff,hi(dc_t7b_test_2+2)	;PC HI
		BYT	$ff,$33			;A
		BYT	$ff,$44			;X
		BYT	$ff,$55			;Y
		BYT	$00,$00			;SR
		BYT	$ff,lo(dc_t7_sp-2)	;SP
		BYT	$ff,hi(dc_t7_sp)	;SPH
		BYT	$ff,hi(dc_t7_zp)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$checkdata	BYT	lo(dc_t7b_test_1+2), hi(dc_t7b_test_1+2)

$$statusdata3	BYT	$ff,lo(dc_t7b_test_3+2)	;PC LO
		BYT	$ff,hi(dc_t7b_test_3+2)	;PC HI
		BYT	$ff,$33			;A
		BYT	$ff,$44			;X
		BYT	$ff,$55			;Y
		BYT	$00,$00			;SR
		BYT	$ff,lo(dc_t7_sp)	;SP
		BYT	$ff,hi(dc_t7_sp)	;SPH
		BYT	$ff,hi(dc_t7_zp)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata4	BYT	$ff,lo(dc_t7b_test_5+2)	;PC LO
		BYT	$ff,hi(dc_t7b_test_5+2)	;PC HI
		BYT	$ff,$33			;A
		BYT	$ff,$44			;X
		BYT	$ff,$55			;Y
		BYT	$00,$00			;SR
		BYT	$ff,lo(dc_t7_sp)	;SP
		BYT	$ff,hi(dc_t7_sp)	;SPH
		BYT	$ff,hi(dc_t7_zp)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata5	BYT	$ff,lo(dc_t7b_test_6+2)	;PC LO
		BYT	$ff,hi(dc_t7b_test_6+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$ff,$44			;X
		BYT	$ff,$55			;Y
		BYT	$ff,%11110111		;SR
		BYT	$ff,lo(dc_t7_sp)	;SP
		BYT	$ff,hi(dc_t7_sp)	;SPH
		BYT	$ff,hi(dc_t7_zp)	;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE
;------------------------------------------------------------------------------
;---	Test8: Bxx, SEx, CLx tests

cc_t8		BYT	def_job_download
		ADR	dc_test8_codeend - dc_test8_codestart		;BYTEno
		ADR	dc_test8_codestart				;Start offset
		ADR	dc_t8_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t8_start					;Drive start address
		BYT	def_job_checkstatus
		ADR	$$statusdata
		BYT	def_job_contexecute
		BYT	def_job_checkvcpuaddr
		ADR	(dc_t8_2+2)
		BYT	def_job_contexecute
		BYT	def_job_checkvcpuaddr
		ADR	(dc_t8_3+2)
		BYT	def_job_contexecute
		BYT	def_job_checkvcpuaddr
		ADR	(dc_t8_4+2)
		BYT	def_job_contexecute
		BYT	def_job_checkvcpusr
		BYT	%00110010		;"Z" bit set
		BYT	def_job_contexecute
		BYT	def_job_checkvcpuaddr
		ADR	(dc_t8_5+2)
		BYT	def_job_contexecute
		BYT	def_job_checkvcpusr
		BYT	%10110000		;"N" bit set
		BYT	def_job_contexecute
		BYT	def_job_checkvcpuaddr
		ADR	(dc_t8_6+2)
		BYT	def_job_contexecute
		BYT	def_job_checkvcpusr
		BYT	%10110001		;"C" bit set
		BYT	def_job_contexecute
		BYT	def_job_checkvcpuaddr
		ADR	(dc_t8_7+2)
		BYT	def_job_contexecute
		BYT	def_job_checkvcpusr
		BYT	%10110000		;"C" bit clear
		BYT	def_job_contexecute
		BYT	def_job_checkvcpusr
		BYT	%01110000		;"V" bit set
		BYT	def_job_contexecute
		BYT	def_job_checkvcpuaddr
		ADR	(dc_t8_8+2)
		BYT	def_job_contexecute
		BYT	def_job_checkvcpusr
		BYT	%00110000		;"V" bit clear
		BYT	def_job_contexecute
		BYT	def_job_checkvcpuaddr	;Check jump backward
		ADR	(dc_t8_9+2)
		BYT	def_job_readyexit

$$statusdata	BYT	$ff,lo(dc_t8_1+2)	;PC LO
		BYT	$ff,hi(dc_t8_1+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$00,$00			;X
		BYT	$00,$00			;Y
		BYT	$ff,%00110000		;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE
;------------------------------------------------------------------------------
;---	Test9: INX/INY/DEX/DEY + flags tests

cc_t9		BYT	def_job_download
		ADR	dc_test9_codeend - dc_test9_codestart		;BYTEno
		ADR	dc_test9_codestart				;Start offset
		ADR	dc_t9_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t9_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory			;Check saved data
		ADR	dc_t9_results_end - dc_t9_results
		ADR	dc_t9_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	$00, %00110010
		BYT	$01, %00110000
		BYT	$00, %00110010
		BYT	$ff, %10110000
		BYT	$00, %00110010
		BYT	$01, %00110000
		BYT	$00, %00110010
		BYT	$ff, %10110000
;------------------------------------------------------------------------------
;---	Test10: ADC tests

cc_t10		BYT	def_job_download
		ADR	dc_test10_codeend - dc_test10_codestart		;BYTEno
		ADR	dc_test10_codestart				;Start offset
		ADR	dc_t10_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t10_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t10_results_end - dc_t10_results
		ADR	dc_t10_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	$7e, $7f, %00110000
		BYT	$7e, $80, %11110000
		BYT	$fe, $ff, %10110000
		BYT	$fe, $00, %00110011
		BYT	$00,      %01110011
;------------------------------------------------------------------------------
;---	Test11: SBC tests

cc_t11		BYT	def_job_download
		ADR	dc_test11_codeend - dc_test11_codestart		;BYTEno
		ADR	dc_test11_codestart				;Start offset
		ADR	dc_t11_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t11_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t11_results_end - dc_t11_results
		ADR	dc_t11_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	$81, $80, %10110001
		BYT	$81, $7f, %01110001
		BYT	$01, $00, %00110011
		BYT	$01, $ff, %10110000
		BYT	$00,      %00110011
;------------------------------------------------------------------------------
;---	Test12: CMP tests

cc_t12		BYT	def_job_download
		ADR	dc_test12_codeend - dc_test12_codestart		;BYTEno
		ADR	dc_test12_codestart				;Start offset
		ADR	dc_t12_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t12_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t12_results_end - dc_t12_results
		ADR	dc_t12_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	%00110011
		BYT	%00110001
		BYT	%10110000
		BYT	%00110011
		BYT	%00110001
		BYT	%10110000
;------------------------------------------------------------------------------
;---	Test13: INC/DEC $zp / $uiop tests

cc_t13		BYT	def_job_download
		ADR	dc_test13_codeend - dc_test13_codestart		;BYTEno
		ADR	dc_test13_codestart				;Start offset
		ADR	dc_t13_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t13_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t13_results_end - dc_t13_results
		ADR	dc_t13_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	$01
		BYT	$00
		BYT	$00
		BYT	$ff
		BYT	%00110000
		BYT	%00110010
		BYT	%00110010
		BYT	%10110000
;------------------------------------------------------------------------------
;---	Test14: ASL/LSR/ROL/ROR $zp / $uiop tests

cc_t14		BYT	def_job_download
		ADR	dc_test14_codeend - dc_test14_codestart		;BYTEno
		ADR	dc_test14_codestart				;Start offset
		ADR	dc_t14_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t14_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t14_results_end - dc_t14_results
		ADR	dc_t14_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	%00001010
		BYT	%10100011
		BYT	%01010000
		BYT	%11000101
		BYT	%00001110
		BYT	%11100011
		BYT	%00000000
		BYT	%11000111
		BYT	%01010100
		BYT	%10101001
		BYT	%00000000
		BYT	%10000000
		BYT	%00110001
		BYT	%10110000
		BYT	%00110001
		BYT	%10110000
		BYT	%00110001
		BYT	%10110000
		BYT	%00110011
		BYT	%10110000
		BYT	%00110001
		BYT	%10110000
		BYT	%00110011
		BYT	%10110000
;------------------------------------------------------------------------------
;---	Test15: ORA test

cc_t15		BYT	def_job_download
		ADR	dc_test15_codeend - dc_test15_codestart		;BYTEno
		ADR	dc_test15_codestart				;Start offset
		ADR	dc_t15_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t15_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t15_results_end - dc_t15_results
		ADR	dc_t15_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	%10100100
		BYT	%00000100
		BYT	%00000000
		BYT	%10110000
		BYT	%00110000
		BYT	%00110010
;------------------------------------------------------------------------------
;---	Test16: AND test

cc_t16		BYT	def_job_download
		ADR	dc_test16_codeend - dc_test16_codestart		;BYTEno
		ADR	dc_test16_codestart				;Start offset
		ADR	dc_t16_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t16_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t16_results_end - dc_t16_results
		ADR	dc_t16_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	%00011011
		BYT	%11011011
		BYT	%11111111
		BYT	%00110000
		BYT	%10110000
		BYT	%10110000
;------------------------------------------------------------------------------
;---	Test17: EOR test

cc_t17		BYT	def_job_download
		ADR	dc_test17_codeend - dc_test17_codestart		;BYTEno
		ADR	dc_test17_codestart				;Start offset
		ADR	dc_t17_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t17_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t17_results_end - dc_t17_results
		ADR	dc_t17_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	%00010011
		BYT	%11000011
		BYT	%00000000
		BYT	%00110000
		BYT	%10110000
		BYT	%00110010
;------------------------------------------------------------------------------
;---	Test18: LDA $uiop,X/Y / STA $uiop,X/Y tests

cc_t18		BYT	def_job_download
		ADR	dc_test18_codeend - dc_test18_codestart		;BYTEno
		ADR	dc_test18_codestart				;Start offset
		ADR	dc_t18_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t18_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t18_results_end - dc_t18_results
		ADR	dc_t18_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	$ff,$ff
		BYT	$11,$22,$33,$44,$55,$66,$77,$88
		BYT	$ff,$ff
		BYT	$55,$55
		BYT	$12,$34,$56,$78,$9a,$bc,$de,$f0
		BYT	$aa,$aa
;------------------------------------------------------------------------------
;---	Test19: LDA+STA $zp,X LDX/STX $zp,Y, LDY/STY $zp,X tests

cc_t19		BYT	def_job_download
		ADR	dc_test19_codeend - dc_test19_codestart		;BYTEno
		ADR	dc_test19_codestart				;Start offset
		ADR	dc_t19_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t19_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t19_results_end - dc_t19_results
		ADR	dc_t19_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	$a5,$a5
		BYT	$11,$22,$33,$44,$55,$66,$77,$88
		BYT	$5a,$5a,$48,$84
;------------------------------------------------------------------------------
;---	Test20: LDA+STA ($zp),Y test

cc_t20		BYT	def_job_download
		ADR	dc_test20_codeend - dc_test20_codestart		;BYTEno
		ADR	dc_test20_codestart				;Start offset
		ADR	dc_t20_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t20_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t20_results_end - dc_t20_results
		ADR	dc_t20_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	$ee,$ee
		BYT	$99,$88,$77,$66,$55,$44,$33,$22
		BYT	$dd,$dd
;------------------------------------------------------------------------------
;---	Test21: LDA+STA ($zp,X) test

cc_t21		BYT	def_job_download
		ADR	dc_test21_codeend - dc_test21_codestart		;BYTEno
		ADR	dc_test21_codestart				;Start offset
		ADR	dc_t21_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t21_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t21_results_end - dc_t21_results
		ADR	dc_t21_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	$99,$99
		BYT	$ee,$11,$dd,$22,$cc,$33,$bb,$44
		BYT	$88,$88
;------------------------------------------------------------------------------
;---	Test22: BIT $zp / $uiop tests

cc_t22		BYT	def_job_download
		ADR	dc_test22_codeend - dc_test22_codestart		;BYTEno
		ADR	dc_test22_codestart				;Start offset
		ADR	dc_t22_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t22_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory				;Check saved data
		ADR	dc_t22_results_end - dc_t22_results
		ADR	dc_t22_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	%00110000
		BYT	%00110000
		BYT	%01110010
		BYT	%01110010
		BYT	%11110010
		BYT	%11110010
;------------------------------------------------------------------------------
;---	Test23: UINDB / UDEDB test

cc_t23		BYT	def_job_download
		ADR	dc_test23_codeend - dc_test23_codestart		;BYTEno
		ADR	dc_test23_codestart				;Start offset
		ADR	dc_t23_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t23_start					;Drive start address
		BYT	def_job_checkstatus
		ADR	$$statusdata1
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata2
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata3
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata4
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata5
		BYT	def_job_contexecute
		BYT	def_job_checkstatus
		ADR	$$statusdata6
		BYT	def_job_readyexit

$$statusdata1	BYT	$ff,lo(dc_t23_p1+2)	;PC LO
		BYT	$ff,hi(dc_t23_p1+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$ff,$55			;X
		BYT	$ff,$01			;Y
		BYT	$00,%00000000		;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata2	BYT	$ff,lo(dc_t23_p1+2)	;PC LO
		BYT	$ff,hi(dc_t23_p1+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$ff,$56			;X
		BYT	$ff,$00			;Y
		BYT	$00,%00000000		;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata3	BYT	$ff,lo(dc_t23_p2+2)	;PC LO
		BYT	$ff,hi(dc_t23_p2+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$ff,$57			;X
		BYT	$ff,$ff			;Y
		BYT	$00,%00000000		;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata4	BYT	$ff,lo(dc_t23_p3+2)	;PC LO
		BYT	$ff,hi(dc_t23_p3+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$ff,$66			;X
		BYT	$ff,$01			;Y
		BYT	$00,%00000000		;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata5	BYT	$ff,lo(dc_t23_p3+2)	;PC LO
		BYT	$ff,hi(dc_t23_p3+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$ff,$65			;X
		BYT	$ff,$00			;Y
		BYT	$00,%00000000		;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE

$$statusdata6	BYT	$ff,lo(dc_t23_p4+2)	;PC LO
		BYT	$ff,hi(dc_t23_p4+2)	;PC HI
		BYT	$00,$00			;A
		BYT	$ff,$64			;X
		BYT	$ff,$ff			;Y
		BYT	$00,%00000000		;SR
		BYT	$00,$00			;SP
		BYT	$00,$00			;SPH
		BYT	$00,$00			;ZPH
		BYT	$ff,vcpu_functioncall	;INTERRUPT
		BYT	$ff,0			;COMMAND
		BYT	$00,$00			;LASTOPCODE
;------------------------------------------------------------------------------
;---	Test24: ATBCD: Convert A register to ASCII decimal chars

cc_t24		BYT	def_job_download
		ADR	dc_test24_codeend - dc_test24_codestart		;BYTEno
		ADR	dc_test24_codestart				;Start offset
		ADR	dc_t24_start					;Drive start address
		BYT	def_job_execute
		ADR	dc_t24_start					;Drive start address
		BYT	def_job_initpointer
		BYT	def_job_readmemory		;Check saved data
		ADR	dc_t24_results_end - dc_t24_results
		ADR	dc_t24_results
		BYT	def_job_checkmemory
		ADR	$$checkdata
		BYT	def_job_readyexit

$$checkdata	BYT	"000"
		BYT	"009"
		BYT	"010"
		BYT	"099"
		BYT	"100"
		BYT	"255"
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
