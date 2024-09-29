;------------------------------------------------------------------------------
;---	SD2IEC test codes
;---	©2023.10.17.+ by BSZ
;---	"C128 only" text for fast serial tests
;------------------------------------------------------------------------------
		jsr	rom_primm
		BYT	ascii_return,"FAST SERIAL IMPLEMENTED ON C128 ONLY!"
		BYT	ascii_return,"IF YOU HAVE ANY HW SOLUTION FOR THIS"
		BYT	ascii_return,"PLATFORM, PLEASE IMPLEMENT THIS TEST!",ascii_return,0
		jmp	program_exit
;------------------------------------------------------------------------------
