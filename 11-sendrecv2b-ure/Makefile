ASP = ../common/assp.sh
ASB = ../common/assb.sh

PRGNAME = k-sr2b-ure
DRVNAME = sr2b-ure-drive

ifndef PLATFORM
$(error PLATFORM not set)
endif

all: $(DRVNAME).bin $(PRGNAME)-$(PLATFORM).prg

$(DRVNAME).bin: *.asm
	$(ASB) $(DRVNAME)

$(PRGNAME)-$(PLATFORM).prg: $(DRVNAME).bin
	$(ASP) $(PRGNAME) $(PLATFORM)
	mv $(PRGNAME).prg $(PRGNAME)-$(PLATFORM).prg
	cp $(PRGNAME)-$(PLATFORM).prg $(PRGNAME)-$(PLATFORM)
	mv $(PRGNAME).lst $(PRGNAME)-$(PLATFORM).lst

clean:
	rm -f $(PRGNAME)-$(PLATFORM).prg $(PRGNAME)-$(PLATFORM).lst $(PRGNAME).inc *-$(PLATFORM)
	rm -f $(DRVNAME).bin $(DRVNAME).lst $(DRVNAME).inc

copy: $(PRGNAME)-$(PLATFORM)
	mkdir -p ../target-$(PLATFORM)
	rm -f ../target-$(PLATFORM)/$(PRGNAME)-$(PLATFORM)
	cp $(PRGNAME)-$(PLATFORM) ../target-$(PLATFORM)

delexec:
	rm -f ../target-$(PLATFORM)/$(PRGNAME)-$(PLATFORM)
	rmdir --ignore-fail-on-non-empty ../target-$(PLATFORM)
