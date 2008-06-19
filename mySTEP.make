#!/usr/bin/make -f
#
ifeq (nil,null)   ## this is to allow for the following text without special comment character considerations
#
# This file is part of mySTEP
#
# Last Change: $Id$
#
# You should not edit this file as it affects all projects you will compile!
#
# Copyright, H. Nikolaus Schaller <hns@computer.org>, 2003-2008
# This document is licenced using LGPL
#
# Requires Xcode 2.4 or later
# And Apple X11 incl. X11 SDK
#
# To use this makefile in Xcode with Xtoolchain:
#
#  1. open the xcode project
#  2. select the intended target in the Targets group
#  3. select from the menu Build/New Build Phase/New Shell Script Build Phase
#  4. select the "Shell Script Files" phase in the target
#  5. open the information (i) or (Apple-I)
#  6. copy the following code into the "Script" area

########################### start cut here ############################

# project settings
export SOURCES=*.m                  # all source codes
export LIBS=						# add any additional libraries like -ltiff etc.
export FRAMEWORKS=					# add any additional Frameworks (e.g. AddressBook) etc. (adds -I and -L)
export INSTALL_PATH=/Applications   # override INSTALL_PATH for MacOS X for the embedded device

# global/compile settings
#export INSTALL=true                # true (or empty) will install locally to $ROOT/$INSTALL_PATH
#export SEND2ZAURUS=true			# true (or empty) will try to install on the embedded device at /$INSTALL_PATH (using ssh)
#export RUN=true                    # true (or empty) will finally try to run on the embedded device (using X11 on host)
export ROOT=$HOME/Documents/Projects/QuantumSTEP	# project root
/usr/bin/make -f $ROOT/System/Sources/Frameworks/mySTEP.make $ACTION

########################### end to cut here ###########################

#  7. change the SRC= line to include all required source files (e.g. main.m other/*.m)
#  8. change the LIBS= line to add any non-standard libraries (e.g. -lAddressBook -lPreferencePane -lWebKit)
#  9. Build the project (either in deployment or development mode - that affects only the MacOS version)
#
endif

.PHONY:	clean build build_architecture

ifeq ($(ARCHITECTURES),)
	ARCHITECTURES := arm-quantumstep-linux-gnu # i386-quantumstep-linux-gnu
endif

build:	# call recursively for all architectures
# arm-hardfloat-linux-gnu
# arm-softfloat-linux-gnueabi
	for ARCH in $(ARCHITECTURES); do \
		echo "*** building for $$ARCH ***"; \
		export ARCHITECTURE=$$ARCH; \
		make -f $(ROOT)/System/Sources/Frameworks/mySTEP.make build_architecture; \
		done

# configure Embedded System if undefined

IP_ADDR$:=$(shell cat /Developer/Xtoolchain/IPaddr 2>/dev/null)

ifeq ($(IP_ADDR),)
	IP_ADDR=192.168.129.201
endif

ifeq ($(EMBEDDED_ROOT),)
	EMBEDDED_ROOT:=/usr/share/QuantumSTEP
endif

ifeq ($(ARCHITECTURE),)
	ARCHITECTURE := arm-quantumstep-linux-gnu
	ARCHITECTURE := i386-quantumstep-linux-gnu
endif

COMPILER := gcc-2.95.3-glibc-2.2.2

# tools
TOOLCHAIN := $(SYSTEM_DEVELOPER_DIR)/Xtoolchain/native/$(COMPILER)/$(ARCHITECTURE)
CC := $(TOOLCHAIN)/bin/gcc
LS := $(TOOLCHAIN)/bin/ld
AS := $(TOOLCHAIN)/bin/as
NM := $(TOOLCHAIN)/bin/nm
STRIP := $(TOOLCHAIN)/bin/strip
TAR := tar
# TAR := $(TOOLS)/gnutar-1.13.25	# use older tar that does not know about ._ resource files

# override if (stripped) package is build using xcodebuild

ifeq ($(BUILD_FOR_DEPLOYMENT),true)
	# optimize for speed
	OPTIMIZE := 3
	# remove headers and symbols
#	STRIP_Framework := true
	# remove MacOS X code
#	STRIP_MacOS := true
	# install in our file system so that we can build the package
	INSTALL := true
	# don't send to the device
	SEND2ZAURUS := false
	# and don't run
	RUN := false
endif

ifeq ($(OPTIMIZE),)
	# default to optimize depending on BUILD_STYLE
	ifeq ($(BUILD_STYLE),Development)
		OPTIMIZE := s
	else
		OPTIMIZE := $(GCC_OPTIMIZATION_LEVEL)
	endif
endif

# check if Zaurus responds
ifeq ($(SEND2ZAURUS),false)
else	# check if we can reach the device
	ifneq "$(shell ping -qc 1 $(IP_ADDR) | fgrep '1 packets received' >/dev/null && echo yes)" "yes"
		SEND2ZAURUS := false
		RUN := false
	endif
endif

# could better check ifeq ($(PRODUCT_TYPE),com.apple.product-type.framework)

# define CONTENTS subdirectory as expected by the Foundation library

ifeq ($(WRAPPER_EXTENSION),)	# command line tool
	CONTENTS=.
	NAME_EXT=$(PRODUCT_NAME)
	PKG=$(BUILT_PRODUCTS_DIR)/$(NAME_EXT).tool
	EXEC=$(PKG)
	BINARY=$(EXEC)/$(NAME_EXT)
else
ifeq ($(WRAPPER_EXTENSION),framework)	# framework
	CONTENTS=Versions/Current
	NAME_EXT=$(PRODUCT_NAME).$(WRAPPER_EXTENSION)
	PKG=$(BUILT_PRODUCTS_DIR)
	EXEC=$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)
	BINARY=$(EXEC)/lib$(EXECUTABLE_NAME).so
	HEADERS=$(EXEC)/Headers/$(PRODUCT_NAME)
	CFLAGS := -shared -Wl,-soname,$(PRODUCT_NAME) -I$(EXEC)/Headers/ $(CFLAGS)
else
	CONTENTS=Contents
	NAME_EXT=$(PRODUCT_NAME).$(WRAPPER_EXTENSION)
	PKG=$(BUILT_PRODUCTS_DIR)
	EXEC=$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)
	BINARY=$(EXEC)/$(EXECUTABLE_NAME)
ifeq ($(WRAPPER_EXTENSION),app)
	CFLAGS := -DFAKE_MAIN $(CFLAGS)	# application
else
	CFLAGS := -shared -Wl,-soname,$(NAME_EXT) $(CFLAGS)	# any other bundle
endif
endif
endif

# system includes&libraries and locate all standard frameworks

INCLUDES := \
		-I$(TOOLCHAIN)/include \
		-I$(ROOT)/usr/include \
		-I$(ROOT)/usr/include/X11 \
		-I$(ROOT)/usr/include/X11/freetype2 \
		-I$(shell sh -c 'echo $(ROOT)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"')

ifeq ($(PRODUCT_NAME),Foundation)
		FMWKS := $(addprefix -l,$(FRAMEWORKS))
else
ifeq ($(PRODUCT_NAME),AppKit)
		FMWKS := $(addprefix -l,Foundation $(FRAMEWORKS))
else
		FMWKS := $(addprefix -l,Foundation AppKit $(FRAMEWORKS))
endif
endif

LIBS := \
		-L$(TOOLCHAIN)/../lib/gcc-lib/$(ARCHITECTURE)/2.95.3/lib \
		-L$(TOOLCHAIN)/lib \
		-L$(ROOT)/usr/lib \
		-L$(ROOT)/usr/lib/$(ARCHITECTURE) \
		-Wl,-rpath-link,$(ROOT)/usr/lib \
		-Wl,-rpath-link,$(ROOT)/usr/lib/$(ARCHITECTURE) \
		-L$(shell sh -c 'echo $(ROOT)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -L/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(ROOT)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		$(FMWKS) \
		$(LIBS)

# set up appropriate CFLAGS for $(ARCHITECTURE)

WARNINGS = -Wall -Wno-shadow -Wpointer-arith -Wno-import

DEFINES =-DLinux_ARM \
		-DARCHITECTURE=@\"$(ARCHITECTURE)\" \
		-D__mySTEP__ \
		-DUSE_BITFIELDS=0 \
		-D_REENTRANT \
		-DHAVE_MMAP \
		-DLONG_LONG_MAX=9223372036854775807L -DLONG_LONG_MIN=-9223372036854775807L -DULONG_LONG_MAX=18446744073709551615UL

CFLAGS := $(CFLAGS) \
		-g -O$(OPTIMIZE) -fPIC -rdynamic \
		$(WARNINGS) \
		$(DEFINES) \
  		$(INCLUDES) \
        $(OTHER_CFLAGS)

ifeq ($(PROFILING),YES)
	CFLAGS :=  -pg $(CFLAGS)
endif

# ifeq ($(GCC_WARN_ABOUT_MISSING_PROTOTYPES),YES)
# CFLAGS :=  -Wxyz $(CFLAGS)
# endif

.SUFFIXES : .o .c .m

.m.o::
	- mkdir -p $(TARGET_BUILD_DIR)/$(ARCHITECTURE)
	@(echo Compiling: $*; echo cd $(TARGET_BUILD_DIR)/$(ARCHITECTURE); echo $(CC) -c -MD $(CFLAGS) $(PWD)/$< -o $*.o)
#	@(echo Compiling: $*; cd $(TARGET_BUILD_DIR)/$(ARCHITECTURE); $(CC) -c -MD $(CFLAGS) $(PWD)/$< -o $*.o)

.c.o:: 	
	- mkdir -p $(TARGET_BUILD_DIR)/arm-linux
	@(echo Compiling: $*; echo cd $(TARGET_BUILD_DIR)/$(ARCHITECTURE); echo $(CC) -c -MD $(CFLAGS) $(PWD)/$< -o $*.o)
#	@(echo Compiling: $*; cd $(TARGET_BUILD_DIR)/$(ARCHITECTURE); $(CC) -c -MD $(CFLAGS) $(PWD)/$< -o $*.o)

XOBJECTS=$(wildcard $(SOURCES:%.m=$(TARGET_BUILD_DIR)$(ARCHITECTURE)/%.o))
OBJECTS=$(SOURCES)

build_architecture: "$(EXEC)" "$(BINARY)"
ifeq ($(ADD_MAC_LIBRARY),true)
	# install locally in /Library/Frameworks
	- $(TAR) czf - --exclude .svn -C "$(PKG)" "$(NAME_EXT)" | (cd '/Library/Frameworks' && (pwd; rm -rf "$(NAME_EXT)" ; tar xpzvf -))
endif
ifeq ($(INSTALL),false)
else
	# install locally $(ROOT)$(INSTALL_PATH) 
	- $(TAR) czf - --exclude .svn -C "$(PKG)" "$(NAME_EXT)" | (mkdir -p '$(ROOT)$(INSTALL_PATH)'; cd '$(ROOT)$(INSTALL_PATH)' && (pwd; rm -rf "$(NAME_EXT)" ; tar xpzvf -))
ifeq ($(SEND2ZAURUS),false)
else
	# install on $(IP_ADDR) at $(EMBEDDED_ROOT)/$(INSTALL_PATH) 
	ls -l "$(BINARY)"
	- $(TAR) czf - --exclude .svn --exclude MacOS --owner 500 --group 1 -C "$(PKG)" "$(NAME_EXT)" | ssh -l root $(IP_ADDR) "cd; mkdir -p '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && cd '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && tar xpzvf -"
ifeq ($(RUN),false)
	# dont launch
else
	# try to launch
	if [ "$(WRAPPER_EXTENSION)" = app ] ; then \
                defaults write com.apple.x11 nolisten_tcp false; \
				open -a X11; \
				export DISPLAY=localhost:0.0; [ -x /usr/X11R6/bin/xhost ] && /usr/X11R6/bin/xhost +$(IP_ADDR) && \
		ssh -l root $(IP_ADDR) \
		"cd; export QuantumSTEP=$(EMBEDDED_ROOT); PATH=\$$PATH:$(EMBEDDED_ROOT)/usr/bin; export LOGNAME=$(LOGNAME); export HOST=\$$(expr \"\$$SSH_CONNECTION\" : '\\(.*\\) .* .* .*'); export DISPLAY=\$$HOST:0.0; set; export EXECUTABLE_PATH=Contents/$(ARCHITECTURE); cd '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && $(EMBEDDED_ROOT)/usr/bin/run '$(PRODUCT_NAME)' -NoNSBackingStoreBuffered" || echo failed to run; \
	fi
endif
endif
endif
	# $(BINARY) built.
	date

clean:
	# ignored

# generic bundle rule

"$(BINARY)":: $(XOBJECTS) $(OBJECTS)
	#
	# compile $(SOURCES) into $(BINARY)
	#
	@mkdir -p "$(EXEC)"
	$(CC) $(CFLAGS) -o "$(BINARY)" $(OBJECTS) $(LIBS)
	# compiled.

# link headers of framework

"$(EXEC)"::
	# make directory for Linux executable
	echo ".o objects" $(XOBJECTS)
	@mkdir -p "$(EXEC)"
ifeq ($(WRAPPER_EXTENSION),framework)
	- [ -r "$(HEADERS)" ] || (mkdir -p "$(EXEC)/Headers" && ln -s ../../Headers "$(HEADERS)")	# link to headers to find <Framework/File.h>
	- rm -f $(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)/$(EXECUTABLE_NAME)
	- ln -s lib$(EXECUTABLE_NAME).so $(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)/$(EXECUTABLE_NAME)	# create libXXX.so entry for ldconfig
endif