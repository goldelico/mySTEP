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
# Copyright, H. Nikolaus Schaller <hns@computer.org>, 2003-2014
# This document is licenced using LGPL
#
# Requires Xcode 3.2 or later
# and Apple X11 incl. X11 SDK
#
# To use this makefile in Xcode with Xtoolchain:
#
#  1. create a project.qcodeproj file
#  2. open through QuantumCode and edit the project definitions
#  3. open the Xcode project
#  4. select the intended target in the Targets group
#  5. select from the menu Build/New Build Phase/New Shell Script Build Phase
#  6. select the "Shell Script Files" phase in the target
#  7. open the information (i) or (Apple-I)
#  8. add the following code into the "Script" area
#     cd path-to qcodeproj; ./project.qcodeproj
#  9. Build the project (either in deployment or development mode)
#
endif

ifeq ($(QuantumSTEP),)
QuantumSTEP:=$(QuantumSTEP)
endif

include $(QuantumSTEP)/System/Sources/Frameworks/Version.def

.PHONY:	clean build build_architecture

# configure Embedded System if undefined

ROOT:=$(QuantumSTEP)

ifeq ($(EMBEDDED_ROOT),)
EMBEDDED_ROOT:=/usr/share/QuantumSTEP
endif

### FIXME: what is the right path???

# DOWNLOAD := $(QuantumSTEP)/System/Sources/System/Tools/ZMacSync/ZMacSync/build/Development/ZMacSync.app/Contents/MacOS/zaurusconnect -l 
DOWNLOAD := $(QuantumSTEP)/System/Library/Frameworks/DeviceManager/Contents/MacOS/qsrsh
DOWNLOAD := $(QuantumSTEP)/System/Sources/PrivateFrameworks/DeviceManager/build/Development/qsrsh

# tools
ifeq ($(shell uname),Darwin)
# use platform specific (cross-)compiler on Darwin host
DOXYGEN := /Applications/Doxygen.app/Contents/Resources/doxygen
# disable special MacOS X stuff for tar
TAR := COPY_EXTENDED_ATTRIBUTES_DISABLED=true COPYFILE_DISABLE=true /usr/bin/gnutar

ifeq ($(PRODUCT_NAME),All)
# Xcode aggregate target
PRODUCT_NAME=$(PROJECT_NAME)
endif

ifeq ($(ARCHITECTURE),i386-apple-darwin)
TOOLCHAIN=/Developer/usr/bin
CC := $(TOOLCHAIN)/gcc-4.0
LD := $(CC)
AS := $(TOOLCHAIN)/as
NM := $(TOOLCHAIN)/nm
STRIP := $(TOOLCHAIN)/strip
SO := dylib
else
ifeq ($(ARCHITECTURE),arm-iPhone-darwin)
TOOLCHAIN=/Developer/Platforms/iPhoneOS.platform/Developer/usr
CC := $(TOOLCHAIN)/bin/arm-apple-darwin9-gcc-4.0.1
else
TOOLCHAIN := $(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/Current/gcc/$(ARCHITECTURE)
CC := LANG=C $(TOOLCHAIN)/$(ARCHITECTURE)/bin/gcc
# CC := clang -march=armv7-a -mfloat-abi=soft -ccc-host-triple $(ARCHITECTURE) -integrated-as --sysroot $(QuantumSTEP) -I$(QuantumSTEP)/include
LD := $(CC) -v -L$(TOOLCHAIN)/$(ARCHITECTURE)/lib -Wl,-rpath-link,$(TOOLCHAIN)/$(ARCHITECTURE)/lib
AS := $(TOOLCHAIN)/bin/$(ARCHITECTURE)-as
NM := $(TOOLCHAIN)/bin/$(ARCHITECTURE)-nm
STRIP := $(TOOLCHAIN)/bin/$(ARCHITECTURE)-strip
endif
SO := so
endif

else
# native compile on target machine
DOXYGEN := doxygen
TAR := tar
## FIXME: allow to cross-compile
TOOLCHAIN := native
CC := gcc
LD := ld
AS := as
NM := nm
STRIP := strip
SO := so
endif

# if we call the makefile not within Xcode
ifeq ($(BUILT_PRODUCTS_DIR),)
BUILT_PRODUCTS_DIR=build/Deployment
endif
ifeq ($(TARGET_BUILD_DIR),)
TARGET_BUILD_DIR=build/Deployment
endif

# define CONTENTS subdirectory as expected by the Foundation library

ifeq ($(EXECUTABLE_NAME),All)
EXECUTABLE_NAME=$(PRODUCT_NAME)
endif

ifeq ($(WRAPPER_EXTENSION),)	# command line tool
	CONTENTS=.
	NAME_EXT=$(PRODUCT_NAME)
	PKG=$(BUILT_PRODUCTS_DIR)/$(ARCHITECTURE)/bin
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
	BINARY=$(EXEC)/lib$(EXECUTABLE_NAME).$(SO)
	HEADERS=$(EXEC)/Headers/$(PRODUCT_NAME)
	CFLAGS := -I$(EXEC)/Headers/ $(CFLAGS)
ifeq ($(ARCHITECTURE),i386-apple-darwin)
	LDFLAGS := -dynamiclib -dylib -undefined dynamic_lookup $(LDFLAGS)
else
	LDFLAGS := -shared -Wl,-soname,$(PRODUCT_NAME) $(LDFLAGS)
endif
else
	CONTENTS=Contents
	NAME_EXT=$(PRODUCT_NAME).$(WRAPPER_EXTENSION)
	PKG=$(BUILT_PRODUCTS_DIR)
	EXEC=$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)
	BINARY=$(EXEC)/$(EXECUTABLE_NAME)
ifeq ($(WRAPPER_EXTENSION),app)
	CFLAGS := -DFAKE_MAIN $(CFLAGS)	# application
else
ifeq ($(ARCHITECTURE),i386-apple-darwin)
	LDFLAGS := -dylib -undefined dynamic_lookup $(LDFLAGS)
else
	LDFLAGS := -shared -Wl,-soname,$(NAME_EXT) $(LDFLAGS)	# any other bundle
endif
endif
endif
endif

# default is to build for all

ifeq ($(DEBIAN_ARCHITECTURES),)
# try to deduce names from $(shell cd $(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/Current/gcc && echo *-*-*)
DEBIAN_ARCHITECTURES=armel armhf i386 # mipsel -ltiff is broken
endif

# this is the default/main target

build:	build_doxy make_php build_debs install_local install_tool deploy_remote launch_remote
	date

build_debs:

### check if meta package
### copy/install $DATA and $FILES
### build_deb (only)
### architecture all-packages are part of machine specific Packages.gz (!)
### there is not necessarily a special binary-all directory but we can do that

### FIXME: directly use the DEBIAN_ARCH names for everything

ifneq ($(DEBIAN_ARCHITECTURES),)
	# recursively make for all architectures $(DEBIAN_ARCHITECTURES)
	for DEBIAN_ARCH in $(DEBIAN_ARCHITECTURES); do \
		case "$$DEBIAN_ARCH" in \
			armel ) export ARCHITECTURE=arm-linux-gnueabi;; \
			armhf ) export ARCHITECTURE=arm-linux-gnueabihf;; \
			i386 ) export ARCHITECTURE=i486-linux-gnu;; \
			mipsel ) export ARCHITECTURE=mipsel-linux-gnu;; \
			all ) export ARCHITECTURE=all;; \
			* ) export ARCHITECTURE=unknown-linux-gnu;; \
		esac; \
		echo "*** building for $$DEBIAN_ARCH using xtc $$ARCHITECTURE ***"; \
		export DEBIAN_ARCH="$$DEBIAN_ARCH"; \
		make -f $(QuantumSTEP)/System/Sources/Frameworks/mySTEP.make build_deb; \
		done
endif

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
DEPLOY := false
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

# workaround for bug in arm-linux-gnueabi toolchain
ifeq ($(ARCHITECTURE),arm-linux-gnueabi)
OPTIMIZE := 3
CFLAGS += -fno-section-anchors -ftree-vectorize -mfpu=neon -mfloat-abi=softfp
endif
ifeq ($(ARCHITECTURE),arm-linux-gnueabihf)
OPTIMIZE := 3
# we could try -mfloat-abi=hardfp
# see https://wiki.linaro.org/Linaro-arm-hardfloat
CFLAGS += -fno-section-anchors -ftree-vectorize # -mfpu=neon -mfloat-abi=hardfp
endif

CFLAGS += -fsigned-char

## FIXME: we need different prefix paths on compile host and embedded!
HOST_INSTALL_PATH := $(QuantumSTEP)/$(INSTALL_PATH)
## prefix by $ROOT unless starting with //
ifneq ($(findstring //,$(INSTALL_PATH)),//)
TARGET_INSTALL_PATH := $(EMBEDDED_ROOT)/$(INSTALL_PATH)
else
TARGET_INSTALL_PATH := $(INSTALL_PATH)
endif

# check if embedded device responds
#ifneq ($(DEPLOY),false) # check if we can reach the device
#ifneq "$(shell ping -qc 1 $(IP_ADDR) | fgrep '1 packets received' >/dev/null && echo yes)" "yes"
#DEPLOY := false
#RUN := false
#endif
#endif

# could better check ifeq ($(PRODUCT_TYPE),com.apple.product-type.framework)

# system includes&libraries and locate all standard frameworks

#		-I$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/include/X11 \
# 		-I$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/include \

INCLUDES := $(INCLUDES) \
		-I$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/include/freetype2 \
		-I$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"') \
		-I$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"') \
		-I$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"')

ifeq ($(ARCHITECTURE),i386-apple-darwin)
INCLUDES += -I$(QuantumSTEP)/System/Sources/Frameworks/macports-dylibs/include -I/usr/include/X11/.. -I/usr/include/X11/../freetype2
endif

# set up appropriate CFLAGS for $(ARCHITECTURE)

# -Wall
WARNINGS =  -Wno-shadow -Wpointer-arith -Wno-import

DEFINES = -DARCHITECTURE=@\"$(ARCHITECTURE)\" \
		-D__mySTEP__ \
		-DHAVE_MMAP

# add -v to debug include search path issues

CFLAGS := $(CFLAGS) \
		-g -O$(OPTIMIZE) -fPIC -rdynamic \
		$(WARNINGS) \
		$(DEFINES) \
		$(INCLUDES) \
		$(OTHER_CFLAGS)

ifeq ($(PROFILING),YES)
CFLAGS := -pg $(CFLAGS)
endif

# ifeq ($(GCC_WARN_ABOUT_MISSING_PROTOTYPES),YES)
# CFLAGS :=  -Wxyz $(CFLAGS)
# endif

# should be solved differently
ifneq ($(ARCHITECTURE),arm-zaurus-linux-gnu)
OBJCFLAGS := $(CFLAGS) -fconstant-string-class=NSConstantString -D_NSConstantStringClassName=NSConstantString
endif

# expand patterns in SOURCES
XSOURCES := $(wildcard $(SOURCES))

# get the objects from all sources we need to compile and link
OBJCSRCS   := $(filter %.m %.mm,$(XSOURCES))
CSRCS   := $(filter %.c %.cpp %.c++,$(XSOURCES))
SRCOBJECTS := $(OBJCSRCS) $(CSRCS)
OBJECTS := $(SRCOBJECTS:%.m=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)
OBJECTS := $(OBJECTS:%.mm=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)
OBJECTS := $(OBJECTS:%.c=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)
OBJECTS := $(OBJECTS:%.cpp=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)
OBJECTS := $(OBJECTS:%.c++=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)

PHPSRCS   := $(filter %.php,$(XSOURCES))
SHSRCS   := $(filter %.sh,$(XSOURCES))

RESOURCES := $(strip $(filter-out $(SRCOBJECTS),$(XSOURCES)))	# all remaining (re)sources
SUBPROJECTS:= $(strip $(filter %.qcodeproj,$(RESOURCES)))	# subprojects
DEBIAN_CONTROL:= $(strip $(filter %.preinst %.postinst %.prerm %.postrm,$(RESOURCES)))	# additional debian control files
# build them in a loop - if not globaly disabled
HEADERSRC := $(strip $(filter %.h,$(RESOURCES)))	# header files
IMAGES := $(strip $(filter %.png %.jpg %.icns %.gif %.tiff,$(RESOURCES)))	# image/icon files

ifeq ($(PRODUCT_NAME),Foundation)
FMWKS := $(addprefix -l,$(FRAMEWORKS))
else
ifeq ($(PRODUCT_NAME),AppKit)
FMWKS := $(addprefix -l,Foundation $(FRAMEWORKS))
else
ifneq ($(strip $(OBJCSRCS)),)	# any objective C source
FMWKS := $(addprefix -l,Foundation AppKit $(FRAMEWORKS))
endif
endif
endif

#		-L$(TOOLCHAIN)/lib \

# FIXME: use $(addprefix -L,$(wildcard $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE))
# and $(addprefix "-Wl,-rpath-link,",$(wildcard $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE))

#		$(addprefix -L,$(wildcard $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE))) \

LIBRARIES := \
		-L$(QuantumSTEP)/usr/lib \
		-L$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/lib \
		-L$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -L/g"') \
		-L$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -L/g"') \
		-L$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -L/g"') \
		$(FMWKS) \
		$(LIBS)

ifneq ($(ARCHITECTURE),i386-apple-darwin)
LIBRARIES := \
		-Wl,-rpath-link,$(QuantumSTEP)/usr/lib \
		-Wl,-rpath-link,$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/lib \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		$(LIBRARIES)
else
LIBRARIES := -L$(QuantumSTEP)/System/Sources/Frameworks/macports-dylibs/lib -L/usr/X11R6/lib $(LIBRARIES)
endif

ifneq ($(OBJCSRCS)$(FMWKS),)
LIBRARIES += -lobjc -lm
ifneq ($(ARCHITECTURE),i386-apple-darwin)
LIBRARIES += -lgcc_s
endif
endif

.SUFFIXES : .o .c .cpp .m

# adding /+ to the file path looks strange but is to avoid problems with ../neighbour/source.m
# if someone knows how to easily substitute ../ by ++/ or .../ in TARGET_BUILD_DIR we could avoid some other minor problems
# FIXME: please use $(subst ...)

$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o: %.m
	@- mkdir -p $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+$(*D)
	# compile $< -> $*.o
	$(CC) -c $(OBJCFLAGS) -E $< -o $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+$*.i	# store preprocessor result for debugging
	$(CC) -c $(OBJCFLAGS) -S $< -o $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+$*.S	# store assembler source for debugging
	$(CC) -c $(OBJCFLAGS) $< -o $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+$*.o

$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o: %.c
	@- mkdir -p $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+$(*D)
	# compile $< -> $*.o
	$(CC) -c $(CFLAGS) $< -o $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+$*.o

$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o: %.cpp
	@- mkdir -p $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+$(*D)
	# compile $< -> $*.o
	$(CC) -c $(CFLAGS) $< -o $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+$*.o

#
# makefile targets
#

make_bundle:
# make bundle

make_exec: "$(EXEC)"
# make exec

ifneq ($(strip $(SRCOBJECTS)),)
make_binary: "$(BINARY)"
	ls -l "$(BINARY)"
else
make_binary:
	# no sources - no binary
endif

make_php:
# make PHP
	for PHP in *.php Sources/*.php; do \
		if [ -r "$$PHP" ]; then mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php" && cp "$$PHP" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/"; fi; \
		done

DOXYDIST = "$(QuantumSTEP)/System/Installation/Doxy"

build_doxy:	build/$(PRODUCT_NAME).docset
	- [ -r build/$(PRODUCT_NAME).docset/html/index.html ] && (cd build && tar cf - $(PRODUCT_NAME).docset) | \
		(mkdir -p $(DOXYDIST) && cd $(DOXYDIST) && rm -rf $(DOXYDIST)/$(PRODUCT_NAME).docset && \
		tar xf - && \
		( echo "<h1>Quantumstep Framework Documentation</h1>"; \
		  echo "<ul>"; \
		  for f in *.docset; \
		  do BN=$$(basename $$f .docset); \
			echo "<li><a href=\"$$BN.docset/html/classes.html\">$$BN.framework</a></li>"; \
		  done; \
		  echo "<ul>" \
		) >index.html )

# rebuild if any header was changed

build/$(PRODUCT_NAME).docset:	$(HEADERSRC)
ifeq ($(WRAPPER_EXTENSION),framework)
ifneq ($(NO_DOXY),true)
	mkdir -p build
	- $(DOXYGEN) -g build/$(PRODUCT_NAME).doxygen
	pwd
	echo "PROJECT_NAME      = \"$(PRODUCT_NAME).$(WRAPPER_EXTENSION)\"" >>build/$(PRODUCT_NAME).doxygen
	echo "PROJECT_BRIEF      = \"a QuantumSTEP framework\"" >>build/$(PRODUCT_NAME).doxygen
#	echo "INPUT = $(SOURCES)" >>build/$(PRODUCT_NAME).doxygen
	echo "INPUT = $^" >>build/$(PRODUCT_NAME).doxygen
#	echo "INPUT = $$PWD" >>build/$(PRODUCT_NAME).doxygen
	echo "OUTPUT_DIRECTORY = $@" >>build/$(PRODUCT_NAME).doxygen
	echo "GENERATE_LATEX   = NO" >>build/$(PRODUCT_NAME).doxygen
	echo "UML_LOOK         = YES" >>build/$(PRODUCT_NAME).doxygen
	echo "RECURSIVE        = YES" >>build/$(PRODUCT_NAME).doxygen
	echo "SOURCE_BROWSER   = NO" >>build/$(PRODUCT_NAME).doxygen
	echo "VERBATIM_HEADERS = YES" >>build/$(PRODUCT_NAME).doxygen
	echo "EXCLUDE_PATTERNS = */build */.svn *.php" >>build/$(PRODUCT_NAME).doxygen
	echo "GENERATE_DOCSET  = YES" >>build/$(PRODUCT_NAME).doxygen
	echo "DOCSET_BUNDLE_ID = com.quantumstep.$(PRODUCT_NAME)" >>build/$(PRODUCT_NAME).doxygen
	- $(DOXYGEN) build/$(PRODUCT_NAME).doxygen && touch $@
#	make -C build/DoxygenDocs.docset/html # install
endif
endif

#
# Debian package builder
# see http://www.debian.org/doc/debian-policy/ch-controlfields.html
#

# add default dependency

# FIXME: eigentlich sollte zu jedem mit mystep-/quantumstep- beginnenden Eintrag von "DEPENDS" ein >= $(VERSION) zugefuegt werden
# damit auch abhaengige Pakete einen Versions-Upgrade bekommen

ifeq ($(DEBIAN_PACKAGE_NAME),)
ifeq ($(WRAPPER_EXTENSION),)
DEBIAN_PACKAGE_NAME = $(shell echo "QuantumSTEP-$(PRODUCT_NAME)" | tr "[:upper:]" "[:lower:]")
else
DEBIAN_PACKAGE_NAME = $(shell echo "QuantumSTEP-$(PRODUCT_NAME)-$(WRAPPER_EXTENSION)" | tr "[:upper:]" "[:lower:]")
endif
endif

ifneq ($(strip $(OBJCSRCS)),)	# any objective C source
ifeq ($(DEBIAN_DESCRIPTION),)
DEBIAN_DESCRIPTION := part of QuantumSTEP Desktop/Palmtop Environment
endif
ifeq ($(DEBIAN_DEPENDS),)
DEPENDS := quantumstep-cocoa-framework
endif
ifeq ($(DEBIAN_HOMEPAGE),)
DEBIAN_HOMEPAGE := www.quantum-step.com
endif
endif

ifeq ($(DEBIAN_DESCRIPTION),)
DEBIAN_DESCRIPTION := built by mySTEP
endif
ifeq ($(DEBIAN_MAINTAINER),)
DEBIAN_MAINTAINER := info <info@goldelico.com>
endif
ifeq ($(DEBIAN_SECTION),)
DEBIAN_SECTION := x11
endif
ifeq ($(DEBIAN_PRIORITY),)
DEBIAN_PRIORITY := optional
endif
ifeq ($(DEBIAN_VERSION),)
DEBIAN_VERSION := 0.$(shell date '+%Y%m%d%H%M%S' )
endif

DEBDIST="$(QuantumSTEP)/System/Installation/Debian/dists/staging/main"

# FIXME: allow to disable -dev and -dbg if we are marked "private"
build_deb: make_bundle make_exec make_binary \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" 

# FIXME: use different /tmp/data subdirectories for each running make
# NOTE: don't include /tmp here to protect against issues after typos

UNIQUE := mySTEP-$(shell date '+%Y%m%d%H%M%S')
TMP_DATA := $(UNIQUE)/data
TMP_CONTROL := $(UNIQUE)/control
TMP_DEBIAN_BINARY := $(UNIQUE)/debian-binary

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb":
	# make debian package $(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb
	# DEBIAN_SECTION: $(DEBIAN_SECTION)
	# DEBIAN_PRIORITY: $(DEBIAN_PRIORITY)
	# DEBIAN_CONTROL: $(DEBIAN_CONTROL)
	# DEBIAN_DEPENDS: $(DEBIAN_DEPENDS)
	# DEBIAN_RECOMMENDS: $(DEBIAN_RECOMMENDS)
	# DEBIAN_REPLACES: $(DEBIAN_REPLACES)
	mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
	- rm -rf "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)"
	- mkdir -p "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)"
ifneq ($(OBJECTS),)
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS --exclude Headers -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && tar xvzf -)
endif
ifneq ($(FILES),)
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS --exclude Headers -C "$(PWD)" $(FILES) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && tar xvzf -)
endif
ifneq ($(DATA),)
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS --exclude Headers -C "$(PWD)" $(DATA) | (cd "/tmp/$(TMP_DATA)/" && tar xvzf -)
endif
	# strip all executables down to the minimum
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name $(ARCHITECTURE) ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" -name '*php' -prune -print -exec rm -rf {} ";"
ifeq ($(WRAPPER_EXTENSION),framework)
	# strip off MacOS X binary for frameworks
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)"
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)"
endif
	find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	mkdir -p "/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts" && echo $(DEBIAN_VERSION) >"/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)_@_$(DEBIAN_ARCH).deb"
	$(TAR) czf "/tmp/$(TMP_DATA).tar.gz" --owner 0 --group 0 -C "/tmp/$(TMP_DATA)" .
	ls -l "/tmp/$(TMP_DATA).tar.gz"
	echo "2.0" >"/tmp/$(TMP_DEBIAN_BINARY)"
	( echo "Package: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Section: $(DEBIAN_SECTION)"; \
	  echo "Priority: $(DEBIAN_PRIORITY)"; \
	  [ "$(DEBIAN_REPLACES)" ] && echo "Replaces: $(DEBIAN_REPLACES)"; \
	  echo "Version: $(DEBIAN_VERSION)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
	  [ "$(DEBIAN_MAINTAINER)" ] && echo "Maintainer: $(DEBIAN_MAINTAINER)"; \
	  [ "$(DEBIAN_HOMEPAGE)" ] && echo "Homepage: $(DEBIAN_HOMEPAGE)"; \
	  [ "$(DEBIAN_SOURCE)" ] && echo "Source: $(DEBIAN_SOURCE)"; \
	  echo "Installed-Size: `du -kHs /tmp/$(TMP_DATA) | cut -f1`"; \
	  [ "$(DEBIAN_DEPENDS)" ] && echo "Depends: $(DEBIAN_DEPENDS)"; \
	  [ "$(DEBIAN_RECOMMENDS)" ] && echo "Recommends: $(DEBIAN_RECOMMENDS)"; \
	  echo "Description: $(DEBIAN_DESCRIPTION)"; \
	) >"/tmp/$(TMP_CONTROL)/control"
	if [ "$(strip $(DEBIAN_CONTROL))" ]; then for i in $(DEBIAN_CONTROL); do cp $$i /tmp/$(TMP_CONTROL)/$${i##*.}; done; fi
	$(TAR) cvzf /tmp/$(TMP_CONTROL).tar.gz --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) .
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	- rm -rf $@
	ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	ls -l $@

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb":
	# FIXME: make also dependent on location (i.e. public */Frameworks/ only)
ifeq ($(WRAPPER_EXTENSION),framework)
	# make debian development package
	mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
	- rm -rf "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)"
	- mkdir -p "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)"
	# don't exclude Headers
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && tar xvzf -)
	# strip all executables down so that they can be linked
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name $(ARCHITECTURE) ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" -name '*php' -prune -print -exec rm -rf {} ";"
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)
	find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	mkdir -p /tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts && echo $(DEBIAN_VERSION) >/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dev_@_$(DEBIAN_ARCH).deb
	$(TAR) czf /tmp/$(TMP_DATA).tar.gz --owner 0 --group 0 -C /tmp/$(TMP_DATA) .
	ls -l /tmp/$(TMP_DATA).tar.gz
	echo "2.0" >"/tmp/$(TMP_DEBIAN_BINARY)"
	( echo "Package: $(DEBIAN_PACKAGE_NAME)-dev"; \
	  echo "Section: $(DEBIAN_SECTION)"; \
	  echo "Priority: extra"; \
	  echo "Version: $(DEBIAN_VERSION)"; \
	  echo "Replaces: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
	  [ "$(DEBIAN_MAINTAINER)" ] && echo "Maintainer: $(DEBIAN_MAINTAINER)"; \
	  [ "$(DEBIAN_HOMEPAGE)" ] && echo "Homepage: $(DEBIAN_HOMEPAGE)"; \
	  [ "$(DEBIAN_SOURCE)" ] && echo "Source: $(DEBIAN_SOURCE)"; \
	  echo "Installed-Size: `du -kHs /tmp/$(TMP_DATA) | cut -f1`"; \
	  [ "$(DEBIAN_DEPENDS)" ] && echo "Depends: $(DEBIAN_DEPENDS)"; \
	  [ "$(DEBIAN_RECOMMENDS)" ] && echo "Recommends: $(DEBIAN_RECOMMENDS)"; \
	  echo "Description: $(DEBIAN_DESCRIPTION)"; \
	) >"/tmp/$(TMP_CONTROL)/control"
	if [ "$(strip $(DEBIAN_CONTROL))" ]; then for i in $(DEBIAN_CONTROL); do cp $$i /tmp/$(TMP_CONTROL)/$${i##*.}; done; fi
	$(TAR) czf /tmp/$(TMP_CONTROL).tar.gz $(DEBIAN_CONTROL) --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) .
	- rm -rf $@
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	ls -l $@
else
	# no development version
endif

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb":
	# FIXME: make also dependent on location (i.e. public */Frameworks/ only)
ifeq ($(WRAPPER_EXTENSION),framework)
	# make debian development package
	mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
	- rm -rf "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)"
	- mkdir -p "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)"
	# don't exclude Headers
	tar czf - --exclude .DS_Store --exclude .svn --exclude MacOS -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && tar xvzf -)
	# strip all executables down so that they can be linked
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name $(ARCHITECTURE) ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" -name '*php' -prune -print -exec rm -rf {} ";"
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)
	# keep symbols find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	mkdir -p /tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts && echo $(DEBIAN_VERSION) >/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dbg_@_$(DEBIAN_ARCH).deb
	$(TAR) czf /tmp/$(TMP_DATA).tar.gz --owner 0 --group 0 -C /tmp/$(TMP_DATA) .
	ls -l /tmp/$(TMP_DATA).tar.gz
	echo "2.0" >"/tmp/$(TMP_DEBIAN_BINARY)"
	( echo "Package: $(DEBIAN_PACKAGE_NAME)-dbg"; \
	  echo "Section: $(DEBIAN_SECTION)"; \
	  echo "Priority: extra"; \
	  echo "Version: $(DEBIAN_VERSION)"; \
	  echo "Replaces: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
	  [ "$(DEBIAN_MAINTAINER)" ] && echo "Maintainer: $(DEBIAN_MAINTAINER)"; \
	  [ "$(DEBIAN_HOMEPAGE)" ] && echo "Homepage: $(DEBIAN_HOMEPAGE)"; \
	  [ "$(DEBIAN_SOURCE)" ] && echo "Source: $(DEBIAN_SOURCE)"; \
	  echo "Installed-Size: `du -kHs /tmp/$(TMP_DATA) | cut -f1`"; \
	  [ "$(DEBIAN_DEPENDS)" ] && echo "Depends: $(DEBIAN_DEPENDS)"; \
	  echo "Description: $(DEBIAN_DESCRIPTION)"; \
	) >"/tmp/$(TMP_CONTROL)/control"
	if [ "$(strip $(DEBIAN_CONTROL))" ]; then for i in $(DEBIAN_CONTROL); do cp $$i /tmp/$(TMP_CONTROL)/$${i##*.}; done; fi
	$(TAR) czf /tmp/$(TMP_CONTROL).tar.gz $(DEBIAN_CONTROL) --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) .
	- rm -rf $@
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	ls -l $@
else
	# no debug version
endif

install_local:
# install_local
ifeq ($(ADD_MAC_LIBRARY),true)
	# install locally in /Library/Frameworks
	- $(TAR) czf - --exclude .svn -C "$(PKG)" "$(NAME_EXT)" | (cd '/Library/Frameworks' && (pwd; rm -rf "$(NAME_EXT)" ; $(TAR) xpzvf -))
	# installed on localhost
else
	# don't install local
endif

install_tool:
ifneq ($(OBJECTS),)
ifneq ($(INSTALL),false)
	$(TAR) czf - --exclude .svn -C "$(PKG)" "$(NAME_EXT)" | (mkdir -p '$(HOST_INSTALL_PATH)' && cd '$(HOST_INSTALL_PATH)' && (pwd; rm -rf "$(NAME_EXT)" ; $(TAR) xpzvf -))
	# installed on localhost at $(HOST_INSTALL_PATH)
else
	# don't install tool
endif
endif

deploy_remote:
ifneq ($(OBJECTS),)
ifneq ($(DEPLOY),false)
	- ls -l "$(BINARY)" # fails because we are on the outer level and have included an empty $DEBIAN_ARCHTIECTURE in $BINARY
	- $(DOWNLOAD) -a | while read DEVICE NAME; \
		do \
		$(TAR) czf - --exclude .svn --exclude MacOS --owner 500 --group 1 -C "$(PKG)" "$(NAME_EXT)" | $(DOWNLOAD) $$DEVICE "cd; mkdir -p '$(TARGET_INSTALL_PATH)' && cd '$(TARGET_INSTALL_PATH)' && gunzip | tar xpvf -" ; \
		echo installed on $$NAME at $(TARGET_INSTALL_PATH); \
		done
	#done
else
	# not deployed
endif
endif

launch_remote:
ifneq ($(OBJECTS),)
ifneq ($(DEPLOY),false)
ifneq ($(RUN),false)
ifeq ($(WRAPPER_EXTENSION),app)
	# try to launch $(RUN) Application
	: defaults write com.apple.x11 nolisten_tcp false; \
	defaults write org.x.X11 nolisten_tcp 0; \
	rm -rf /tmp/.X0-lock /tmp/.X11-unix; open -a X11; sleep 5; \
	export DISPLAY=localhost:0.0; [ -x /usr/X11R6/bin/xhost ] && /usr/X11R6/bin/xhost + && \
	RUN=$$($(DOWNLOAD) -r) | head -n 1) \
	[ "$$RUN" ] && $(DOWNLOAD) $$RUN \
		"cd; set; export QuantumSTEP=$(EMBEDDED_ROOT); export PATH=\$$PATH:$(EMBEDDED_ROOT)/usr/bin; export LOGNAME=$(LOGNAME); export NSLog=yes; export HOST=\$$(expr \"\$$SSH_CONNECTION\" : '\\(.*\\) .* .* .*'); export DISPLAY=\$$HOST:0.0; export LOGNAME=user; set; export EXECUTABLE_PATH=Contents/$(ARCHITECTURE); cd '$(TARGET_INSTALL_PATH)' && run '$(PRODUCT_NAME)' $(RUN_OPTIONS)" \
		|| echo failed to run;
endif		
endif
endif
endif

clean:
	# ignored

# generic bundle rule

### add rules or code to copy the Info.plist and Resources if not done by Xcode
### so that this makefile can be used independently of Xcode to create full bundles

# FIXME: use dependencies to link only if any object file has changed

"$(BINARY)":: headers $(OBJECTS)
	# link $(SRCOBJECTS) -> $(OBJECTS) -> $(BINARY)
	@mkdir -p "$(EXEC)"
	$(LD) $(LDFLAGS) -o "$(BINARY)" $(OBJECTS) $(LIBRARIES)
	$(NM) -u "$(BINARY)"
	# compiled.

# link headers of framework

headers:
ifeq ($(WRAPPER_EXTENSION),framework)
ifneq ($(strip $(HEADERSRC)),)
	# included header files $(HEADERSRC)
	- (mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" && cp $(HEADERSRC) "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" )	# copy headers
endif
	- (mkdir -p "$(EXEC)/Headers" && rm -f $(HEADERS) && ln -sf ../../Headers "$(HEADERS)")	# link to headers to find <Framework/File.h>
endif

"$(EXEC)":: headers
	# make directory for Linux executable
	# SOURCES: $(SOURCES)
	# SRCOBJECTS: $(SRCOBJECTS)
	# OBJCSRCS: $(OBJCSRCS)
	# OBJECTS: $(OBJECTS)
	# RESOURCES: $(RESOURCES)
	# HEADERS: $(HEADERSRC)
	# SUBPROJECTS: $(SUBPROJECTS)
	mkdir -p "$(EXEC)"
ifeq ($(WRAPPER_EXTENSION),framework)
	# link shared library for frameworks
	- rm -f $(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)/$(EXECUTABLE_NAME)
	- ln -sf lib$(EXECUTABLE_NAME).$(SO) $(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)/$(EXECUTABLE_NAME)	# create libXXX.so entry for ldconfig
endif

# EOF