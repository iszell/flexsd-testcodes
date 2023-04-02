ifndef target_platform
target_platform=none
endif
ifeq ($(target_platform),)
target_platform=none
endif
ifeq ($(target_platform), vic20)
PLATFORM=20
endif
ifeq ($(target_platform), c64)
PLATFORM=64
endif
ifeq ($(target_platform), c264)
PLATFORM=264
endif
ifeq ($(target_platform), c128)
PLATFORM=128
endif

ifndef PLATFORM
$(info Please set "target_platform"!)
$(info Parameters:)
$(info "target_platform=vic20" <- VIC20)
$(info "target_platform=c64"   <- C64)
$(info "target_platform=c264"  <- C264 (C16 / C116 / plus/4))
$(info "target_platform=c128"  <- C128)
$(error "target_platform" not set)
endif

SAMPLES = $(wildcard ??-*)

all:
	for ACTUAL in $(SAMPLES); do \
	  ( $(MAKE) -C $$ACTUAL PLATFORM=$(PLATFORM) ) || exit $$?; \
	  ( $(MAKE) -C $$ACTUAL copy PLATFORM=$(PLATFORM) ) || exit $$?; \
	done

clean:
	for ACTUAL in $(SAMPLES); do \
	  $(MAKE) -C $$ACTUAL clean PLATFORM=$(PLATFORM); \
	done

delexec:
	for ACTUAL in $(SAMPLES); do \
	  $(MAKE) -C $$ACTUAL delexec PLATFORM=$(PLATFORM); \
	done
