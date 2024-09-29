;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2021.09.17.+ by BSZ
;---	VCPU core test - misc
;------------------------------------------------------------------------------
def_job_readyexit	=	0
def_job_download	=	1
def_job_execute		=	2
def_job_setexecute	=	3
def_job_contexecute	=	4
def_job_getvcpustatus	=	5
def_job_checkstatus	=	6
def_job_initpointer	=	7
def_job_readmemory	=	8
def_job_checkmemory	=	9
def_job_setjob		=	10
def_job_checkjob	=	11
def_job_checkvcpusr	=	12
def_job_checkvcpuaddr	=	13
def_job_checkminvcpuver	=	14
def_job_checkextstatus	=	15
;------------------------------------------------------------------------------
;---	VCPU core test routine: run phases
coretests	ldx	#lo(phaseaddrlist)
		ldy	#hi(phaseaddrlist)
		stx	z_sal
		sty	z_sah				;Init testphases list
		lda	#$ff
		sta	_testno+0
		sta	_testno+1			;Starting test number = $FFFF
		jsr	rom_primm
		BYT	ascii_return,ascii_return,"TESTS START:",0

$$testcycle	inc	_testno+0
		bne	$$tc_nc
		inc	_testno+1			;Next phase number
$$tc_nc		ldy	#0
		lda	(z_sal),y
		sta	getbyte_testdescriptor+1
		iny
		lda	(z_sal),y
		sta	getbyte_testdescriptor+2
		ora	getbyte_testdescriptor+1
		bne	$$tc_nextphase
		jsr	rom_primm
		BYT	ascii_return,"TESTS END.",0
		rts
$$tc_nextphase	jsr	rom_primm
		BYT	ascii_return,"TEST #",0
		ldx	_testno+0
		lda	_testno+1			;A:X: number of test
		jsr	bas_linprt
		jsr	run_test_phase
		bcs	$$phaseerror
		bit	_testskip
		bpl	$$pass
		asl	_testskip			;Clear SKIP sign
		jsr	rom_primm
		BYT	" SKIP",0
		jmp	$$continue
$$pass		jsr	rom_primm
		BYT	" PASS",0
$$continue	clc
		lda	z_sal
		adc	#2
		sta	z_sal
		bcc	$$testcycle
		inc	z_sah
		bne	$$testcycle			;BRA

$$phaseerror	jsr	rom_primm
		BYT	ascii_return, "TEST ERROR!!!",0
;;;
		rts

_testno		ADR	$0000			;Phase number
;------------------------------------------------------------------------------
;---	Get next byte from test-descriptor, increment pointer:

getbyte_testdescriptor

		lda	$ffff
		php
		inc	getbyte_testdescriptor+1
		bne	$$ncy
		inc	getbyte_testdescriptor+2
$$ncy		plp
		rts
;------------------------------------------------------------------------------
;---	Run one test:
run_test_phase	jsr	getbyte_testdescriptor	;Get Job's number
		asl	a			;*2
		tax
		lda	$$jobs+0,x
		sta	$$jobcall+1
		lda	$$jobs+1,x
		sta	$$jobcall+2
$$jobcall	jsr	$ffff			;Self-modify code: call function
		bcc	run_test_phase
		rts

$$jobs		ADR	$$normalexit		;def_job_readyexit	=	0
		ADR	job_download		;def_job_download	=	1
		ADR	job_execute		;def_job_execute	=	2
		ADR	job_setexecute		;def_job_setexecute	=	3
		ADR	job_contexecute		;def_job_contexecute	=	4
		ADR	$$errorexit		;def_job_getvcpustatus	=	5
		ADR	job_checkstatus		;def_job_checkstatus	=	6
		ADR	job_initpointer		;def_job_initpointer	=	7
		ADR	job_readmemory		;def_job_readmemory	=	8
		ADR	job_checkmemory		;def_job_checkmemory	=	9
		ADR	job_setjob		;def_job_setjob		=	10
		ADR	$$errorexit		;def_job_checkjob	=	11
		ADR	job_checkvcpusr		;def_job_checkvcpusr	=	12
		ADR	job_checkvcpuaddr	;def_job_checkvcpuaddr	=	13
		ADR	job_checkminvcpuver	;def_job_checkminvcpuver =	14
		ADR	job_checkextstatus	;def_job_checkextstatus	=	15

$$normalexit	pla
		pla			;Drop return address
		clc			;CLC: OK
		rts

$$errorexit	pla
		pla			;Drop return address
		sec			;SEC: ERROR
		rts
;------------------------------------------------------------------------------
;---	Download bytes to drive:
job_download	jsr	getbyte_testdescriptor		;ByteNo Lo
		sta	$$len+0
		jsr	getbyte_testdescriptor		;ByteNo Hi
		sta	$$len+1
		clc
		jsr	getbyte_testdescriptor		;Source address offset Lo
		adc	#lo(_drivecodes)
		sta	$$src+0
		jsr	getbyte_testdescriptor		;Source address offset Hi
		adc	#hi(_drivecodes)
		sta	$$src+1
		jsr	getbyte_testdescriptor		;Destination address Lo
		sta	$$dest+0
		jsr	getbyte_testdescriptor		;Destination address Hi
		sta	$$dest+1
		jsr	sd2i_writememory
$$src		ADR	$ffff				;Source address in computer memory
$$len		ADR	$ffff				;BYTEno
$$dest		ADR	$ffff				;Destination address in drive memory
		clc					;OK...
		rts
;------------------------------------------------------------------------------
;---	Simple execute:
job_execute	jsr	getbyte_testdescriptor		;Drive start address Lo
		tax
		jsr	getbyte_testdescriptor		;Drive start address Hi
		tay
		jsr	sd2i_execmemory_simple

_execrecvres	ldx	#1
		jsr	wait_frames
		jsr	sd2i_getvcpustatus		;Get VCPU status
		clc					;OK...
		rts
;------------------------------------------------------------------------------
;---	Execute: Fill VCPU registers and execute:
job_setexecute	jsr	getbyte_testdescriptor		;Bytes to registers
		sta	$$byteno+1
		jsr	getbyte_testdescriptor		;Register values Lo
		sta	$$rdmem+1
		jsr	getbyte_testdescriptor		;Register values Hi
		sta	$$rdmem+2
		ldx	#0
$$rdmem		lda	$ffff,x
		sta	$$vcpuregs+2,x
		inx
$$byteno	cpx	#12
		bne	$$rdmem

		clc
		lda	$$byteno+1
		adc	#2
		ldx	#lo($$vcpuregs)
		ldy	#hi($$vcpuregs)
		jmp	_execute

$$vcpuregs	BYT	"ZE",0,0,0,0,0,0,0,0,0,0,0,0
;------------------------------------------------------------------------------
;---	Execute: continue VCPU execution to actual address
job_contexecute	lda	#2
		ldx	#lo($$ze)
		ldy	#hi($$ze)
		jmp	_execute
$$ze		BYT	"ZE"

_execute	jsr	sd2i_sendcommand
		jmp	_execrecvres
;------------------------------------------------------------------------------
;---	Check VCPU status, extended regs (VCPU R2):
job_checkextstatus
		ldx	#12
		lda	#18
		bne	_job_chkstatus

;---	Compare VCPU status:
job_checkstatus	ldx	#0
		lda	#12

_job_chkstatus	sta	$$statlen+1
		jsr	getbyte_testdescriptor		;Required VCPU status data address Lo
		sta	z_eal
		jsr	getbyte_testdescriptor		;Required VCPU status data address Hi
		sta	z_eah
		ldy	#0
$$statuschk	lda	_vcpustatus,x			;Received VCPU status
		and	(z_eal),y			;AND with mask
		iny
		cmp	(z_eal),y			;Compare with required
		bne	printvcpustatus_err
		iny
		inx
$$statlen	cpx	#$ff				;PCL,PCH,A,X,Y,SR,SP,SPH,ZPH,INTERRUPT,COMMAND,LASTOPCODE,RRL,RRH,U1RL,U1RH,U2RL,U2RH
		bne	$$statuschk
		clc					;OK!
		rts

printvcpustatus_err

		jsr	rom_primm
		BYT	ascii_return,"VCPU STATE:",0
		ldx	#0
		ldy	#0
		jsr	printmem_setdispaddr
		ldx	#lo(_vcpustatus)
		ldy	#hi(_vcpustatus)
		lda	_vcpustatus_siz			;#12/#18
		jsr	printmem
		sec
		rts
;------------------------------------------------------------------------------
;---	Init memory pointer:
job_initpointer	lda	#lo(_membuffer)
		sta	_rdmemptr+0
		lda	#hi(_membuffer)
		sta	_rdmemptr+1
		lda	#0
		sta	_rdmembyteno+0
		sta	_rdmembyteno+1
		clc					;OK...
		rts
;------------------------------------------------------------------------------
;---	Read drive memory:
job_readmemory	clc
		jsr	getbyte_testdescriptor		;ByteNo Lo
		sta	_rdmemlen+0
		adc	_rdmembyteno+0
		sta	_rdmembyteno+0
		jsr	getbyte_testdescriptor		;ByteNo Hi
		sta	_rdmemlen+1
		adc	_rdmembyteno+1
		sta	_rdmembyteno+1
		jsr	getbyte_testdescriptor		;Source address Lo
		sta	$$src+0
		jsr	getbyte_testdescriptor		;Source address Hi
		sta	$$src+1
		jsr	sd2i_readmemory
$$src		ADR	$ffff				;Source address in drive memory
_rdmemlen	ADR	$ffff				;BYTEno
_rdmemptr	ADR	$ffff				;Destination address in drive memory
		clc
		lda	_rdmemptr+0
		adc	_rdmemlen+0
		sta	_rdmemptr+0
		lda	_rdmemptr+1
		adc	_rdmemlen+1
		sta	_rdmemptr+1
		clc					;OK...
		rts

_rdmembyteno	ADR	0
;------------------------------------------------------------------------------
;---	Check memory:
job_checkmemory	jsr	getbyte_testdescriptor		;Source address Lo
		sta	$$compare+1
		jsr	getbyte_testdescriptor		;Source address Hi
		sta	$$compare+2
		ldx	#0
$$compare	lda	$ffff,x
		cmp	_membuffer,x
		bne	$$mismatch
		inx
		cpx	_rdmembyteno+0
		bne	$$compare
		clc					;OK!
		rts

$$mismatch	jsr	rom_primm
		BYT	ascii_return,"VCPU MEMORY:",0
		ldx	#$00
		ldy	#$80
		jsr	printmem_setdispaddr
		ldx	#lo(_membuffer)
		ldy	#hi(_membuffer)
		lda	_rdmembyteno+0
		jsr	printmem
		sec					;ERROR!
		rts
;------------------------------------------------------------------------------
;---	Call subroutine:
job_setjob	jsr	getbyte_testdescriptor		;Subroutine address Lo
		sta	$$call+1
		jsr	getbyte_testdescriptor		;Subroutine address Hi
		sta	$$call+2
$$call		jsr	$ffff				;Call subroutine
		clc					;OK...
		rts
;------------------------------------------------------------------------------
;---	Check VCPU SR:
job_checkvcpusr	jsr	getbyte_testdescriptor		;Required SR value
		cmp	_vcpustatus+5			;Received VCPU SR
		bne	$$error
		clc					;OK!
		rts

$$error		jmp	printvcpustatus_err		;Print VCPU status + SEC: ERROR!
;------------------------------------------------------------------------------
;---	Check VCPU ADDR:
job_checkvcpuaddr
		jsr	getbyte_testdescriptor		;Required PCL value
		tax
		jsr	getbyte_testdescriptor		;Required PCH value
		cpx	_vcpustatus+0			;Received VCPU PCL
		bne	$$error
		cmp	_vcpustatus+1			;Received VCPU PCH
		bne	$$error
		clc					;OK!
		rts

$$error		jmp	printvcpustatus_err		;Print VCPU status + SEC: ERROR!
;------------------------------------------------------------------------------
;---	Check VCPU version (If older, test SKIP)
job_checkminvcpuver

		jsr	getbyte_testdescriptor		;Minimal VCPU version
		cmp	_vcpurev
		beq	$$okay
		bcc	$$okay
		lda	#%10000000
		sta	_testskip			;SKIP sign
		pla
		pla					;Drop return address

$$okay		clc					;OK!
		rts

_testskip	BYT	%00000000
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
