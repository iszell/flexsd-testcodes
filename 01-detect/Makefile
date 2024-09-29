ASP = ../common/assp.sh

PRGNAME = a-detect

ifndef PLATFORM
$(error PLATFORM not set)
endif

$(PRGNAME)-$(PLATFORM).prg: *.asm
	$(ASP) $(PRGNAME) $(PLATFORM)
	mv $(PRGNAME).prg $(PRGNAME)-$(PLATFORM).prg
	cp $(PRGNAME)-$(PLATFORM).prg $(PRGNAME)-$(PLATFORM)
	mv $(PRGNAME).lst $(PRGNAME)-$(PLATFORM).lst

clean:
	rm -f $(PRGNAME)-$(PLATFORM).prg $(PRGNAME)-$(PLATFORM).lst *.inc *-$(PLATFORM)

copy: $(PRGNAME)-$(PLATFORM)
	mkdir -p ../target-$(PLATFORM)
	rm -f ../target-$(PLATFORM)/$(PRGNAME)-$(PLATFORM)
	cp $(PRGNAME)-$(PLATFORM) ../target-$(PLATFORM)

delexec:
	rm -f ../target-$(PLATFORM)/$(PRGNAME)-$(PLATFORM)
	rmdir --ignore-fail-on-non-empty ../target-$(PLATFORM)
