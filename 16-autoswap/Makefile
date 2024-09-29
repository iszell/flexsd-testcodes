ASP = ../common/assp.sh
ASB = ../common/assb.sh

PRGNAME = p-autoswap
DRVNAME = autoswap-drive
IMGNAM1 = vcputstdsk1.d64
IMGNAM2 = vcputstdsk2.d64
SWAPLST = autoswap.lst

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
	cp -u ../common/$(IMGNAM1) ../target-$(PLATFORM)
	cp -u ../common/$(IMGNAM2) ../target-$(PLATFORM)
	cp -u ../common/$(SWAPLST) ../target-$(PLATFORM)

delexec:
	rm -f ../target-$(PLATFORM)/$(PRGNAME)-$(PLATFORM)
	rm -f ../target-$(PLATFORM)/$(IMGNAM1)
	rm -f ../target-$(PLATFORM)/$(IMGNAM2)
	rm -f ../target-$(PLATFORM)/$(SWAPLST)
	rmdir --ignore-fail-on-non-empty ../target-$(PLATFORM)
