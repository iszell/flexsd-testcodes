
	cpu	6502				;CPU type
	page	0,0

hi		function x,(x>>8)&255

lo		function x,x&255

hilo		function x,((x>>8)&255)+((x&255)<<8)

cascii	macro
		charset 'A','Z',97
		charset 'a','z',65
	endm

cbmscii	macro
		charset 'A','Z',1
		charset 'a','z',1
		charset '@',0
		charset '[',27
		charset ']',29
		charset '^',30
	endm

ascii	macro
		charset 0,255,0
	endm
