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
# Requires Xcode 2.5 or later
# and Apple X11 incl. X11 SDK
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

# variables inherited from Xcode environment (or version.def)
# PROJECT_NAME
# PRODUCT_NAME						# e.g. Foundation
# WRAPPER_EXTENSION					# e.g. .framework
# EXECUTABLE_NAME
# BUILT_PRODUCTS_DIR
# TARGET_BUILD_DIR
# BUILD_NUMBER						# used for package versioning

# project settings for cross-compiler (that can't be derived from the Xcode project)
export SOURCES=*.m                  # all source codes (no cross-compilation if empty)
export LIBS=						# add any additional libraries like -ltiff etc. (space separated list)
export FRAMEWORKS=					# add any additional Frameworks (e.g. AddressBook) etc. (adds -I and -L)
export INSTALL_PATH=/Applications   # override INSTALL_PATH for MacOS X for the embedded device
#export ADD_MAC_LIBRARY=			# true to store a copy in /Library/Frameworks on the build host (needed for demo apps)

# global/compile settings
#export INSTALL=true                # true (or empty) will install locally to $ROOT/$INSTALL_PATH
#export SEND2ZAURUS=true			# true (or empty) will try to install on the embedded device at /$INSTALL_PATH (using ssh)
#export RUN=true                    # true (or empty) will finally try to run on the embedded device (using X11 on host)
#export RUN_OPTIONS=-NoNSBackingStoreBuffered
#export BUILD_FOR_DEPLOYMENT=		# true to generate optimized code and strip binaries
#export	PREINST=./preinst			# preinst file
#export	POSTRM=./postrm				# preinst file

# Debian packages
export DEPENDS="quantumstep-cocoa-framework"	# debian package dependencies (, separated list)
# export DEBIAN_PACKAGE_NAME="quantumstep"	# manually define package name
# export FILES=""					# list of other files to be added to the package (relative to $ROOT)
# export DATA=""					# directory of other files to be added to the package (relative to /)

# start make script
export ROOT=/usr/share/QuantumSTEP	# project root
/usr/bin/make -f $ROOT/System/Sources/Frameworks/mySTEP.make $ACTION

########################### end to cut here ###########################

#  7. change the SRC= line to include all required source files (e.g. main.m other/*.m)
#  8. change the LIBS= line to add any non-standard libraries (e.g. -lsqlite3)
#  9. Build the project (either in deployment or development mode)
#
endif

include $(ROOT)/System/Sources/Frameworks/Version.def

.PHONY:	clean build build_architecture

ifeq ($(ARCHITECTURES),)
ifeq ($(BUILD_FOR_DEPLOYMENT),true)
# set all architectures for which we know a compiler (should also check that we have a libobjc.so for this architecture!)
# and that other libraries and include directories are available...
# should exclude i386-apple-darwin
ARCHITECTURES=$(shell cd $(ROOT)/System/Library/Frameworks/System.framework/Versions/Current/gcc && echo *-*-*)
endif
endif

ifeq ($(ARCHITECTURES),)	# try to read from ZMacSync
ARCHITECTURES:=$(shell defaults read de.dsitri.ZMacSync SelectedArchitecture 2>/dev/null)
endif

ifeq ($(ARCHITECTURES),)	# still not defined
ARCHITECTURES=i486-debianetch-linux-gnu
endif

# configure Embedded System if undefined

ifeq ($(EMBEDDED_ROOT),)
EMBEDDED_ROOT:=/usr/share/QuantumSTEP
endif

IP_ADDR:=$(shell defaults read de.dsitri.ZMacSync SelectedHost 2>/dev/null)

ifeq ($(IP_ADDR),)	# set a default
IP_ADDR:=192.168.129.201
endif

# FIXME: zaurusconnect (rename to zrsh) should simply know how to access the currently selected device

DOWNLOAD := $(EMBEDDED_ROOT)/System/Sources/System/Tools/ZMacSync/ZMacSync/build/Development/ZMacSync.app/Contents/MacOS/zaurusconnect -l 

ROOT:=/usr/share/QuantumSTEP

# tools
# use platform specific cross-compiler
ifeq ($(ARCHITECTURE),arm-iPhone-darwin)
TOOLCHAIN=/Developer/Platforms/iPhoneOS.platform/Developer/usr
CC := $(TOOLCHAIN)/bin/arm-apple-darwin9-gcc-4.0.1
else
TOOLCHAIN := $(ROOT)/System/Library/Frameworks/System.framework/Versions/Current/gcc/$(ARCHITECTURE)
CC := $(TOOLCHAIN)/bin/$(ARCHITECTURE)-gcc
endif
LS := $(TOOLCHAIN)/bin/$(ARCHITECTURE)-ld
AS := $(TOOLCHAIN)/bin/$(ARCHITECTURE)-as
NM := $(TOOLCHAIN)/bin/$(ARCHITECTURE)-nm
STRIP := $(TOOLCHAIN)/bin/$(ARCHITECTURE)-strip
# TAR := tar

# disable special MacOS X stuff for tar
TAR := COPY_EXTENDED_ATTRIBUTES_DISABLED=true COPYFILE_DISABLE=true /usr/bin/gnutar
# TAR := $(TOOLS)/gnutar-1.13.25	# use older tar that does not know about ._ resource files
# TAR := $(ROOT)/this/bin/gnutar

# aggregate target
ifeq ($(PRODUCT_NAME),All)
PRODUCT_NAME=$(PROJECT_NAME)
endif

## FIXME: handle meta packages without WRAPPER_EXTENSION; PRODUCT_NAME = "All" ?
## i.e. target type Aggregate

# define CONTENTS subdirectory as expected by the Foundation library

ifeq ($(WRAPPER_EXTENSION),)	# command line tool
	CONTENTS=.
	NAME_EXT=$(PRODUCT_NAME)
	PKG=$(BUILT_PRODUCTS_DIR)/$(NAME_EXT).tool
	EXEC=$(PKG)
	BINARY=$(EXEC)/$(NAME_EXT)
	# architecture specific version (only if it does not yet have the prefix
ifneq (,$(findstring ///System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE),//$(INSTALL_PATH)))
	INSTALL_PATH := /System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)$(INSTALL_PATH)
endif
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

build:
### check if meta package
### copy/install $DATA and $FILES
### use ARCHITECTURE=all
### build_deb (only)
### architecture all-packages are part of machine specific Packages.gz (!)
### there is not necessarily a special binary-all directory but we can do that

### FIXME: directly use the DEBIAN_ARCH names for everything

	# make for all architectures $(ARCHITECTURES)
	for DEBIAN_ARCH in i386 armel mipsel; do \
		case "$$DEBIAN_ARCH" in \
			i386 ) export ARCHITECTURE=i486-debianetch-linux-gnu;; \
			arm ) export ARCHITECTURE=arm-zaurus-linux-gnu;; \
			armel ) export ARCHITECTURE=armv4t-angstrom-linux-gnueabi;; \
			mipsel ) export ARCHITECTURE=mipsel-debianetch-linux-gnu;; \
			? ) export ARCHITECTURE=unknown-debian-linux-gnu;; \
		esac; \
		echo "*** building for $$DEBIAN_ARCH using cross-tools $$ARCHITECTURE ***"; \
		export DEBIAN_ARCH="$$DEBIAN_ARCH"; \
		make -f $(ROOT)/System/Sources/Frameworks/mySTEP.make build_deb; \
		done		
	for ARCH in $(ARCHITECTURES); do \
		if [ "$$ARCH" = "i386-apple-darwin" ] ; then continue; fi; \
		echo "*** building for $$ARCH ***"; \
		export ARCHITECTURE="$$ARCH"; \
		export ARCHITECTURES="$$ARCHITECTURES"; \
		make -f $(ROOT)/System/Sources/Frameworks/mySTEP.make build_architecture; \
		done

__dummy__:
	# dummy target to allow for comments while setting more make variables
	
	# override if (stripped) package is build using xcodebuild

ifeq ($(BUILD_FOR_DEPLOYMENT),true)
# ifneq ($(BUILD_STYLE),Development)
	# optimize for speed
OPTIMIZE := 2
	# should also remove headers and symbols
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

	# default to optimize depending on BUILD_STYLE
ifeq ($(OPTIMIZE),)
ifeq ($(BUILD_STYLE),Development)
OPTIMIZE := s
else
OPTIMIZE := $(GCC_OPTIMIZATION_LEVEL)
endif
endif

# check if embedded device responds
ifneq ($(SEND2ZAURUS),false) # check if we can reach the device
ifneq "$(shell ping -qc 1 $(IP_ADDR) | fgrep '1 packets received' >/dev/null && echo yes)" "yes"
SEND2ZAURUS := false
RUN := false
endif
endif

# could better check ifeq ($(PRODUCT_TYPE),com.apple.product-type.framework)

# system includes&libraries and locate all standard frameworks

INCLUDES := \
		-I$(ROOT)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/include \
		-I$(ROOT)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/include/X11 \
		-I$(ROOT)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/include/freetype2 \
		-I$(shell sh -c 'echo $(ROOT)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"') \
		-I$(shell sh -c 'echo $(ROOT)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"')

ifeq ($(PRODUCT_NAME),Foundation)
FMWKS := $(addprefix -l,$(FRAMEWORKS))
else
ifeq ($(PRODUCT_NAME),AppKit)
FMWKS := $(addprefix -l,Foundation $(FRAMEWORKS))
else
FMWKS := $(addprefix -l,Foundation AppKit $(FRAMEWORKS))
endif
endif

LIBRARIES := \
		-L$(TOOLCHAIN)/lib \
		-L$(ROOT)/usr/lib \
		-Wl,-rpath-link,$(ROOT)/usr/lib \
		-L$(ROOT)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/lib \
		-Wl,-rpath-link,$(ROOT)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/lib \
		-L$(shell sh -c 'echo $(ROOT)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -L/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(ROOT)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		-L$(shell sh -c 'echo $(ROOT)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -L/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(ROOT)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		$(FMWKS) \
		$(LIBS)

# set up appropriate CFLAGS for $(ARCHITECTURE)

# -Wall
WARNINGS =  -Wno-shadow -Wpointer-arith -Wno-import

DEFINES = -DARCHITECTURE=@\"$(ARCHITECTURE)\" \
		-D__mySTEP__ \
		-DUSE_BITFIELDS=0 \
		-D_REENTRANT \
		-DHAVE_MMAP \
		-DLONG_LONG_MAX=9223372036854775807L -DLONG_LONG_MIN=-9223372036854775807L -DULONG_LONG_MAX=18446744073709551615UL

# add -v to debug include search path issues

CFLAGS := $(CFLAGS) \
		-g -O$(OPTIMIZE) -fPIC -rdynamic \
		$(WARNINGS) \
		$(DEFINES) \
		$(INCLUDES) \
		$(OTHER_CFLAGS)

# should be solved differently
ifneq ($(ARCHITECTURE),arm-zaurus-linux-gnu)
CFLAGS := $(CFLAGS) -fconstant-string-class=NSConstantString -D_NSConstantStringClassName=NSConstantString
endif

ifeq ($(PROFILING),YES)
CFLAGS := -pg $(CFLAGS)
endif

# ifeq ($(GCC_WARN_ABOUT_MISSING_PROTOTYPES),YES)
# CFLAGS :=  -Wxyz $(CFLAGS)
# endif

#.SUFFIXES : .o .c .m

#.m.o::
#	- mkdir -p $(TARGET_BUILD_DIR)/$(ARCHITECTURE)
#	@(echo Compiling: $*; echo cd $(TARGET_BUILD_DIR)/$(ARCHITECTURE); echo $(CC) -c -MD $(CFLAGS) $(PWD)/$< -o $*.o)
#	@(echo Compiling: $*; cd $(TARGET_BUILD_DIR)/$(ARCHITECTURE); $(CC) -c -MD $(CFLAGS) $(PWD)/$< -o $*.o)

#.c.o:: 	
#	- mkdir -p $(TARGET_BUILD_DIR)/arm-linux
#	@(echo Compiling: $*; echo cd $(TARGET_BUILD_DIR)/$(ARCHITECTURE); echo $(CC) -c -MD $(CFLAGS) $(PWD)/$< -o $*.o)
#	@(echo Compiling: $*; cd $(TARGET_BUILD_DIR)/$(ARCHITECTURE); $(CC) -c -MD $(CFLAGS) $(PWD)/$< -o $*.o)

XOBJECTS=$(wildcard $(SOURCES:%.m=$(TARGET_BUILD_DIR)$(ARCHITECTURE)/%.o))
OBJECTS=$(SOURCES)

build_architecture: make_bundle make_exec make_binary install_local install_tool install_remote launch_remote
	# $(BINARY) for $(ARCHITECTURE) built.
	date

make_bundle:

make_exec: "$(EXEC)"

ifneq ($(SOURCES),)
make_binary: "$(BINARY)"
	ls -l "$(BINARY)"
else
make_binary:
endif

#
# Debian package builder
# see http://www.debian.org/doc/debian-policy/ch-controlfields.html
#

# add default dependency

ifeq ($(DEPENDS),)
DEPENDS := "quantumstep-cocoa-framework"
endif

# FIXME: eigentlich sollte zu jedem mit mystep-/quantumstep- beginnenden Eintrag von "DEPENDS" ein >= $(VERSION) zugefügt werden
# damit auch abhängige Pakete einen Versions-Upgrade bekommen

ifeq ($(DEBIAN_PACKAGE_NAME),)
ifeq ($(WRAPPER_EXTENSION),)
DEBIAN_PACKAGE_NAME = $(shell echo "QuantumSTEP-$(PRODUCT_NAME)" | tr "[:upper:]" "[:lower:]")
else
DEBIAN_PACKAGE_NAME = $(shell echo "QuantumSTEP-$(PRODUCT_NAME)-$(WRAPPER_EXTENSION)" | tr "[:upper:]" "[:lower:]")
endif
endif

# we should better use current svnversion instead of global BUILD_NUMBER
# this allows to rebuild packages with updated numbers just after checkin of changes

# DEBIAN_VERSION = 0.$(BUILD_NUMBER)
SVN_VERSION := $(shell svnversion)
DEBIAN_VERSION := 0.$(shell if expr "$(SVN_VERSION)" : '.*:.*' >/dev/null; then expr "$(SVN_VERSION)" : '.*:\([0-9]*\).*' + 200; else expr "$(SVN_VERSION)" : '\([0-9]*\).*' + 200; fi )

# FIXME: allow to disable -dev and -dbg if we are marked "private"
build_deb: make_bundle make_exec make_binary install_tool \
	"$(ROOT)/System/Installation/Debian/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(ROOT)/System/Installation/Debian/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" 

"$(ROOT)/System/Installation/Debian/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb":
	# make debian package $(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb
	mkdir -p "$(ROOT)/System/Installation/Debian/binary-$(DEBIAN_ARCH)" "$(ROOT)/System/Installation/Debian/archive"
	- rm -rf /tmp/data
	- mkdir -p "/tmp/data/$(ROOT)$(INSTALL_PATH)"
ifneq ($(SOURCES),)
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS --exclude Headers -C "$(ROOT)$(INSTALL_PATH)" $(NAME_EXT) | (mkdir -p "/tmp/data/$(ROOT)$(INSTALL_PATH)" && cd "/tmp/data/$(ROOT)$(INSTALL_PATH)" && tar xvzf -)
endif
ifneq ($(FILES),)
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS --exclude Headers -C "$(PWD)" $(FILES) | (mkdir -p "/tmp/data/$(ROOT)$(INSTALL_PATH)" && cd "/tmp/data/$(ROOT)$(INSTALL_PATH)" && tar xvzf -)
endif
ifneq ($(DATA),)
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS --exclude Headers -C "$(PWD)/$(DATA)" . | (cd "/tmp/data/" && tar xvzf -)
endif
	# strip all executables down to the minimum
	find /tmp/data "(" -name '*-*-linux-gnu*' ! -name $(ARCHITECTURE) ")" -prune -print -exec rm -rf {} ";"
ifeq ($(WRAPPER_EXTENSION),framework)
	# strip MacOS X binary for frameworks
	rm -rf /tmp/data/$(ROOT)$(INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)
	rm -rf /tmp/data/$(ROOT)$(INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)
endif
	find /tmp/data -type f -perm +a+x -exec $(STRIP) {} \;
	mkdir -p /tmp/data/$(ROOT)/Library/Receipts && echo $(DEBIAN_VERSION) >/tmp/data/$(ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)_@_$(DEBIAN_ARCH).deb
	$(TAR) czf /tmp/data.tar.gz --owner 0 --group 0 -C /tmp/data .
	ls -l /tmp/data.tar.gz
	echo "2.0" >/tmp/debian-binary
	( echo "Package: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Version: $(DEBIAN_VERSION)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
	  echo "Maintainer: info@goldelico.com"; \
	  echo "Homepage: http://www.quantum-step.com"; \
	  echo "Depends: $(DEPENDS)"; \
	  echo "Section: x11"; \
	  echo "Installed-Size: `du -kHs /tmp/data | cut -f1`"; \
	  echo "Priority: optional"; \
	  echo "Description: this is part of mySTEP/QuantumSTEP"; \
	) >/tmp/control
	$(TAR) czf /tmp/control.tar.gz -C /tmp ./control
	- mv -f "$(ROOT)/System/Installation/Debian/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_"*"_$(DEBIAN_ARCH).deb" "$(ROOT)/System/Installation/Debian/archive" 2>/dev/null
	- rm -rf $@
	ar -r -cSv $@ /tmp/debian-binary /tmp/control.tar.gz /tmp/data.tar.gz
	ls -l $@

"$(ROOT)/System/Installation/Debian/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb":
	# FIXME: make also dependent on location (i.e. public */Frameworks/ only)
ifeq ($(WRAPPER_EXTENSION),framework)
	# make debian development package
	mkdir -p "$(ROOT)/System/Installation/Debian/binary-$(DEBIAN_ARCH)" "$(ROOT)/System/Installation/Debian/archive"
	- rm -rf /tmp/data
	- mkdir -p "/tmp/data/$(ROOT)$(INSTALL_PATH)"
	# explicitly include Headers
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS -C "$(ROOT)$(INSTALL_PATH)" $(NAME_EXT) | (mkdir -p "/tmp/data/$(ROOT)$(INSTALL_PATH)" && cd "/tmp/data/$(ROOT)$(INSTALL_PATH)" && tar xvzf -)
	# strip all executables down so that they can be linked
	find /tmp/data -name '*-*-linux-gnu*' ! -name $(ARCHITECTURE) -exec rm -rf {} ";" -prune
	rm -rf /tmp/data/$(ROOT)$(INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)
	rm -rf /tmp/data/$(ROOT)$(INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)
	find /tmp/data -type f -perm +a+x -exec $(STRIP) {} \;
	mkdir -p /tmp/data/$(ROOT)/Library/Receipts && echo $(DEBIAN_VERSION) >/tmp/data/$(ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dev_@_$(DEBIAN_ARCH).deb
	$(TAR) czf /tmp/data.tar.gz --owner 0 --group 0 -C /tmp/data .
	ls -l /tmp/data.tar.gz
	echo "2.0" >/tmp/debian-binary
	( echo "Package: $(DEBIAN_PACKAGE_NAME)-dev"; \
	  echo "Replaces: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Version: $(DEBIAN_VERSION)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
	  echo "Maintainer: info@goldelico.com"; \
	  echo "Homepage: http://www.quantum-step.com"; \
	  echo "Depends: $(DEPENDS)"; \
	  echo "Section: x11"; \
	  echo "Installed-Size: `du -kHs /tmp/data | cut -f1`"; \
	  echo "Priority: optional"; \
	  echo "Description: this is part of mySTEP/QuantumSTEP"; \
	) >/tmp/control
	$(TAR) czf /tmp/control.tar.gz -C /tmp ./control
	- rm -rf $@
	- mv -f "$(ROOT)/System/Installation/Debian/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_"*"_$(DEBIAN_ARCH).deb" "$(ROOT)/System/Installation/Debian/archive" 2>/dev/null
	ar -r -cSv $@ /tmp/debian-binary /tmp/control.tar.gz /tmp/data.tar.gz
	ls -l $@
else
	# no development version
endif

install_local:
ifeq ($(ADD_MAC_LIBRARY),true)
	# install locally in /Library/Frameworks
	- $(TAR) czf - --exclude .svn -C "$(PKG)" "$(NAME_EXT)" | (cd '/Library/Frameworks' && (pwd; rm -rf "$(NAME_EXT)" ; $(TAR) xpzvf -))
else
	# don't install local
endif
	
install_tool:
ifneq ($(SOURCES),)
ifneq ($(INSTALL),false)
	$(TAR) czf - --exclude .svn -C "$(PKG)" "$(NAME_EXT)" | (mkdir -p '$(ROOT)$(INSTALL_PATH)' && cd '$(ROOT)$(INSTALL_PATH)' && (pwd; rm -rf "$(NAME_EXT)" ; $(TAR) xpzvf -))
else
	# don't install tool
endif
endif

install_remote:
ifneq ($(SOURCES),)
ifneq ($(SEND2ZAURUS),false)
	ls -l "$(BINARY)"
	- $(TAR) czf - --exclude .svn --exclude MacOS --owner 500 --group 1 -C "$(PKG)" "$(NAME_EXT)" | $(DOWNLOAD) "cd; mkdir -p '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && cd '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && gunzip | tar xpvf -"
	# installed on $(IP_ADDR) at $(EMBEDDED_ROOT)/$(INSTALL_PATH)
else
	# don't install on $(IP_ADDR)
endif
endif

launch_remote:
ifneq ($(SOURCES),)
ifneq ($(SEND2ZAURUS),false)
ifneq ($(RUN),false)
ifeq ($(WRAPPER_EXTENSION),app)
	# try to launch $(RUN) Application
	: defaults write com.apple.x11 nolisten_tcp false; \
	defaults write org.x.X11 nolisten_tcp 0; \
	rm -f /tmp/.X0-lock; open -a X11; sleep 5; \
	export DISPLAY=localhost:0.0; [ -x /usr/X11R6/bin/xhost ] && /usr/X11R6/bin/xhost +$(IP_ADDR) && \
	$(DOWNLOAD) \
		"cd; set; export QuantumSTEP=$(EMBEDDED_ROOT); PATH=\$$PATH:$(EMBEDDED_ROOT)/usr/bin; export LOGNAME=$(LOGNAME); export NSLog=memory; export HOST=\$$(expr \"\$$SSH_CONNECTION\" : '\\(.*\\) .* .* .*'); export DISPLAY=\$$HOST:0.0; set; export EXECUTABLE_PATH=Contents/$(ARCHITECTURE); cd '$(EMBEDDED_ROOT)/$(INSTALL_PATH)' && $(EMBEDDED_ROOT)/usr/bin/run '$(PRODUCT_NAME)' $(RUN_OPTIONS)" || echo failed to run;
endif		
endif
endif
endif

clean:
	# ignored

# generic bundle rule

### add rules to copy the Info.plist and Resources if not done by Xcode
### so that this makefile can be used independently of Xcode to create full bundles

"$(BINARY)":: $(XOBJECTS) $(OBJECTS)
	#
	# compile $(SOURCES) into $(BINARY)
	#
	@mkdir -p "$(EXEC)"
	$(CC) $(CFLAGS) -o "$(BINARY)" $(OBJECTS) $(LIBRARIES)
	# compiled.

# link headers of framework

headers:
ifeq ($(WRAPPER_EXTENSION),framework)
# fixme: copy only public headers and recognize changes!
	- [ -r "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" ] || (mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" && cp Sources/*.h "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" )	# copy headers (FIXME: only public!)
	- [ -r "$(HEADERS)" ] || (mkdir -p "$(EXEC)/Headers" && ln -s ../../Headers "$(HEADERS)")	# link to headers to find <Framework/File.h>
endif

"$(EXEC)":: headers
	# make directory for Linux executable
	# echo ".o objects: " $(XOBJECTS)
	@mkdir -p "$(EXEC)"
ifeq ($(WRAPPER_EXTENSION),framework)
	# link shared library for frameworks
	- rm -f $(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)/$(EXECUTABLE_NAME)
	- ln -sf lib$(EXECUTABLE_NAME).so $(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)/$(EXECUTABLE_NAME)	# create libXXX.so entry for ldconfig
endif

# EOF