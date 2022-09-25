AS = ../common/ass.sh

PRGNAME = j-sr2b-usr
DRVNAME = sr2b-usr-drive

ifndef PLATFORM
$(error PLATFORM not set)
endif

all: $(DRVNAME).prg $(PRGNAME)-$(PLATFORM).prg

$(DRVNAME).prg: *.asm
	$(AS) $(DRVNAME)

$(PRGNAME)-$(PLATFORM).prg: $(DRVNAME).prg
	$(AS) $(PRGNAME) $(PLATFORM)
	mv $(PRGNAME).prg $(PRGNAME)-$(PLATFORM).prg
	cp $(PRGNAME)-$(PLATFORM).prg $(PRGNAME)-$(PLATFORM)
	mv $(PRGNAME).lst $(PRGNAME)-$(PLATFORM).lst

clean:
	rm -f $(PRGNAME)-$(PLATFORM).prg $(PRGNAME)-$(PLATFORM).lst $(PRGNAME).inc *-$(PLATFORM)
	rm -f $(DRVNAME).prg $(DRVNAME).lst $(DRVNAME).inc

copy: $(PRGNAME)-$(PLATFORM)
	mkdir -p ../target-$(PLATFORM)
	rm -f ../target-$(PLATFORM)/$(PRGNAME)-$(PLATFORM)
	cp $(PRGNAME)-$(PLATFORM) ../target-$(PLATFORM)

delexec:
	rm -f ../target-$(PLATFORM)/$(PRGNAME)-$(PLATFORM)
	rmdir --ignore-fail-on-non-empty ../target-$(PLATFORM)
