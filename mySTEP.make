#!/usr/bin/make -f
#
ifeq (nil,null)   ## this is to allow for the following text without special comment character considerations
#
# This file is part of Zaurus-X-gcc
#
# Last Change: $Id$
#
# You should not edit this file as it affects all projects you will compile!
#
# Copyright, H. Nikolaus Schaller <hns@computer.org>, 2003-2007
# This document is licenced using LGPL
#
# Requires Xcode 2.4
# And Apple X11 incl. X11 SDK
#
# To use this makefile in Xcode with Zaurus-X-gcc:
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
export INSTALL_PATH=/Applications   # override INSTALL_PATH for MacOS X for the Zaurus

# global/compile settings
#export INSTALL=true                # true (or empty) will install locally to $ROOT/$INSTALL_PATH
#export SEND2ZAURUS=true			# true (or empty) will try to install on the Zaurus at /$INSTALL_PATH (using ssh)
#export RUN=true                    # true (or empty) will finally try to run on the Zaurus (using X11 on host)
export ROOT=$HOME/Documents/Projects/QuantumSTEP	# project root
/usr/bin/make -f $ROOT/System/Sources/Frameworks/mySTEP.make $ACTION

########################### end to cut here ###########################

#  7. change the SRC= line to include all required source files (e.g. main.m other/*.m)
#  8. change the LIBS= line to add any non-standard libraries (e.g. -lAddressBook -lPreferencePane -lWebKit)
#  9. Build the project (either in deployment or development mode - that affects only the MacOS version)
#
endif

.PHONY:	clean build

# configure Embedded System if undefined

ARCHITECTURE=arm-quantumstep-linux-gnu
# ARCHITECTURE=arm-hardfloat-linux-gnu
# ARCHITECTURE=arm-softfloat-linux-gnueabi

COMPILER=gcc-2.95.3-glibc-2.2.2

ifeq ($(EMBEDDED_ROOT),)
	EMBEDDED_ROOT:=/usr/share/QuantumSTEP
endif

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
	# default to optimize for space
	OPTIMIZE := s
endif

ZAURUS:=$(shell cat /Developer/Xtoolchain/IPaddr)

ifeq ($(ZAURUS),)
	ZAURUS=192.168.129.201
endif

# check if Zaurus responds
ifeq ($(SEND2ZAURUS),false)
else	# check if we can reach the device
	ifneq "$(shell ping -qc 1 $(ZAURUS) | fgrep '1 packets received' >/dev/null && echo yes)" "yes"
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

# change only if needed
# tools
#TOOLCHAIN := $(SYSTEM_DEVELOPER_DIR)/Zaurus-X-gcc/opt/Embedix/tools/arm-linux
# TOOLCHAIN := $(SYSTEM_DEVELOPER_DIR)/Xtoolchain/native/gcc-2.95.3-glibc-2.2.2/arm-quantumstep-linux-gnu/arm-quantumstep-linux-gnu
TOOLCHAIN := $(SYSTEM_DEVELOPER_DIR)/Xtoolchain/native/$(COMPILER)/$(ARCHITECTURE)/$(ARCHITECTURE)
# TOOLS := $(SYSTEM_DEVELOPER_DIR)/Zaurus-X-gcc/tools
CC := $(TOOLCHAIN)/bin/gcc
LS := $(TOOLCHAIN)/bin/ld
AS := $(TOOLCHAIN)/bin/as
NM := $(TOOLCHAIN)/bin/nm
STRIP := $(TOOLCHAIN)/bin/strip
TAR := tar
# TAR := $(TOOLS)/gnutar-1.13.25	# use older tar that does not know about ._ resource files

# system includes&libraries and locate all standard frameworks

INCLUDES := \
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
		-L$(TOOLCHAIN)/../lib/gcc-lib/arm-quantumstep-linux-gnu/2.95.3/lib \
		-L$(ROOT)/usr/lib \
		-Wl,-rpath-link,$(ROOT)/usr/lib \
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

build: "$(EXEC)" "$(BINARY)"
ifeq ($(INSTALL),false)
else
	# install locally $(ROOT)$(INSTALL_PATH) 
	- $(TAR) czf - --exclude .svn -C "$(PKG)" "$(NAME_EXT)" | (mkdir -p '$(ROOT)$(INSTALL_PATH)'; cd '$(ROOT)$(INSTALL_PATH)' && (pwd; rm -rf "$(NAME_EXT)" ; tar xpzvf -))
ifeq ($(SEND2ZAURUS),false)
else
	# install on $(ZAURUS) at $(EMBEDDED_ROOT)/$(INSTALL_PATH) 
	ls -l "$(BINARY)"
	- $(TAR) czf - --exclude .svn --exclude MacOS --owner 500 --group 1 -C "$(PKG)" "$(NAME_EXT)" | ssh -l root $(ZAURUS) "cd; mkdir -p '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && cd '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && tar xpzvf -"
	# try to launch
ifeq ($(RUN),false)
else
	if [ "$(WRAPPER_EXTENSION)" = app ] ; then \
                defaults write com.apple.x11 nolisten_tcp false; \
				open -a X11; \
				export DISPLAY=localhost:0.0; /usr/X11R6/bin/xhost +$(ZAURUS) && \
		ssh -l zaurus $(ZAURUS) \
		"cd; export QuantumSTEP=$(EMBEDDED_ROOT); PATH=\$$PATH:$(EMBEDDED_ROOT)/usr/bin; export LOGNAME=zaurus; export HOST=\$$(expr \"\$$SSH_CONNECTION\" : '\\(.*\\) .* .* .*'); export DISPLAY=\$$HOST:0.0; set; export EXECUTABLE_PATH=Contents/$(ARCHITECTURE); cd '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && $(EMBEDDED_ROOT)/usr/bin/run '$(PRODUCT_NAME)' -NoNSBackingStoreBuffered" ;\
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