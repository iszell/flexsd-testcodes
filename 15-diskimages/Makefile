AS = ../common/ass.sh

PRGNAME = o-diskimgs
DRVNAME = diskimgs-drive
IMGNAM1 = vcputstdsk1.d64
IMGNAM2 = vcputstdsk2.d64

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
	cp -u ../common/$(IMGNAM1) ../target-$(PLATFORM)
	cp -u ../common/$(IMGNAM2) ../target-$(PLATFORM)

delexec:
	rm -f ../target-$(PLATFORM)/$(PRGNAME)-$(PLATFORM)
	rm -f ../target-$(PLATFORM)/$(IMGNAM1)
	rm -f ../target-$(PLATFORM)/$(IMGNAM2)
	rmdir --ignore-fail-on-non-empty ../target-$(PLATFORM)
