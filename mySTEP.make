#!/usr/bin/make -f
#
ifeq (nil,null)   ## this is to allow for the following text without special comment character considerations
#
# This file is part of mySTEP
#
# Last Change: $Id: mySTEP.make 3263 2014-04-07 09:44:11Z hns $
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
# environment Variable dependencies
#  Entries marked with * should be defined in the .qcodeproj
#  Entries market with + should be defined by the caller of the .qcodeproj
#  Entries with () are optional
#  Entries with - should not be set
#  general setup
#   (*) QuantumSTEP - root of QuantumSTEP
#  sources (input)
#   * SOURCES
#   (*) INCLUDES
#   (*) CFLAGS
#   PROFILING
#   (*) FMWKS
#   (*) LIBS
#  compile control
#   () NOCOMPILE
#   () BUILT_PRODUCTS_DIR - default: build/Deployment
#   () TARGET_BUILD_DIR - default: build/Deployment
#   (+) PHPONLY
#   (+) RECURSIVE
#   (+) BUILD_FOR_DEPLOYMENT
#   (+) OPTIMIZE
#   BUILD_STYLE
#   GCC_OPTIMIZATION_LEVEL
#   () BUILD_DOCUMENTATION
#  bundle definitions (output)
#   * PROJECT_NAME
#   PRODUCT_NAME - the product name (if "All", then PROJECT_NAME is taken)
#   * WRAPPER_EXTENSION
#   (FRAMEWORK_VERSION)
#   - EXECUTABLE_NAME - (if "All", then PRODUCT_NAME is taken)
#   - ARCHITECTURE - the architecture triple to use
#   * DEBIAN_ARCHITECTURES - default
#  Debian packaging (postprocess 1)
#   * DEBIAN_PACKAGE_NAME - quantumstep-$PRODUCT_NAME-$WRAPPER-extension
#   * DEBIAN_DEPENDS - quantumstep-cocoa-framework
#   (*) DEBIAN_HOMEPAGE - www.quantum-step.com
#   (*) DEBIAN_DESCRIPTION
#   (*) DEBIAN_MAINTAINER
#   (*) DEBIAN_SECTION - x11
#   (*) DEBIAN_PRIORITY - optional
#   - DEBIAN_VERSION - current date/time
#   (*) FILES
#   (*) DATA
#  download and test (postprocess 2)
#   () EMBEDDED_ROOT - root on embedded device (default /usr/share/QuantumSTEP)
#   * INSTALL_PATH
#   - INSTALL
#   (+) DEPLOY
#   (+) RUN
#   (+) RUN_CMD
#
# targets
#   build:		build everything (outer level)
#   build_deb:	called recursively to build for a specific debian architecture
#   clean:		clears build directory (not for subprojects)

endif

ifeq ($(QuantumSTEP),)
QuantumSTEP:=/usr/share/QuantumSTEP
endif

ifeq ($(EMBEDDED_ROOT),)
EMBEDDED_ROOT:=/usr/share/QuantumSTEP
endif

INSTALL:=true

include $(QuantumSTEP)/System/Sources/Frameworks/Version.def

.PHONY:	clean build build_deb build_architectures build_subprojects build_doxy make_php install_local deploy_remote launch_remote bundle headers

# configure Embedded System if undefined

ROOT:=$(QuantumSTEP)

### FIXME: what is the right path???

# FIXME: this does only work on the Mac! On embedded the qsrsh is in /usr/bin/$HOST_ARCH or $PATH
DOWNLOAD := $(QuantumSTEP)/usr/bin/qsrsh

# tools
ifeq ($(shell uname),Darwin)
# use platform specific (cross-)compiler on Darwin host
DOXYGEN := /Applications/Doxygen.app/Contents/Resources/doxygen
# disable special MacOS X stuff for tar
TAR := COPY_EXTENDED_ATTRIBUTES_DISABLED=true COPYFILE_DISABLE=true /opt/local/bin/gnutar

ifeq ($(PRODUCT_NAME),All)
# Xcode aggregate target
PRODUCT_NAME=$(PROJECT_NAME)
endif

ifeq ($(ARCHITECTURE),MacOS)
TOOLCHAIN=/usr/bin
CC := $(TOOLCHAIN)/gcc
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
ifeq ($(EXECUTABLE_NAME),)
# FIXME: should extract from Info.plist
EXECUTABLE_NAME=$(PRODUCT_NAME)
endif

ifeq ($(WRAPPER_EXTENSION),)	# command line tool
	CONTENTS=.
	# shared between all binary tools
	NAME_EXT=bin
	# this keeps the binaries separated for installation/packaging
	PKG=$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).bin
	EXEC=$(PKG)/$(NAME_EXT)/$(ARCHITECTURE)
	BINARY=$(EXEC)/$(PRODUCT_NAME)
	# architecture specific version (only if it does not yet have the prefix)
ifneq (,$(findstring ///System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE),//$(INSTALL_PATH)))
	INSTALL_PATH := /System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)$(INSTALL_PATH)
endif
else
ifeq ($(WRAPPER_EXTENSION),framework)	# framework
ifeq ($(FRAMEWORK_VERSION),)	# empty
	# default
	FRAMEWORK_VERSION=A
endif
CONTENTS=Versions/Current
	NAME_EXT=$(PRODUCT_NAME).$(WRAPPER_EXTENSION)
	PKG=$(BUILT_PRODUCTS_DIR)
	EXEC=$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)
	BINARY=$(EXEC)/lib$(EXECUTABLE_NAME).$(SO)
	HEADERS=$(EXEC)/Headers/$(PRODUCT_NAME)
	CFLAGS := -I$(EXEC)/Headers/ $(CFLAGS)
ifeq ($(ARCHITECTURE),MacOS)
	LDFLAGS := -dynamiclib -install_name @rpath/$(NAME_EXT)/Versions/Current/$(PRODUCT_NAME) -undefined dynamic_lookup $(LDFLAGS)
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
ifeq ($(ARCHITECTURE),MacOS)
	LDFLAGS := -dynamiclib -install_name @rpath/$(NAME_EXT)/Versions/Current/MacOS/$(PRODUCT_NAME) -undefined dynamic_lookup $(LDFLAGS)
else
	LDFLAGS := -shared -Wl,-soname,$(NAME_EXT) $(LDFLAGS)	# any other bundle
endif
endif
endif
endif

# default is to build for all

ifeq ($(DEBIAN_ARCHITECTURES),)
# try to deduce names from $(shell cd $(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/Current/gcc && echo *-*-*)
DEBIAN_ARCHITECTURES=macos armel armhf i386 # mipsel: -ltiff is broken
endif

# this is the default/main target on the outer level

ifeq ($(NOCOMPILE),true)
build:	build_subprojects build_doxy install_local
else
build:	build_subprojects build_doxy build_architectures make_php install_local deploy_remote launch_remote
endif
	date

clean:	# also clean for subprojects???
	rm -rf build

### check for debian meta package creation
### copy/install $DATA and $FILES
### build_deb (only)
### architecture all-packages are part of machine specific Packages.gz (!)
### there is not necessarily a special binary-all directory but we can do that

### FIXME: directly use the DEBIAN_ARCH names for everything

build_architectures:
ifneq ($(DEBIAN_ARCHITECTURES),)
ifneq ($(DEBIAN_ARCHITECTURES),none)
	# recursively make for all architectures $(DEBIAN_ARCHITECTURES)
	for DEBIAN_ARCH in $(DEBIAN_ARCHITECTURES); do \
		case "$$DEBIAN_ARCH" in \
			armel ) export ARCHITECTURE=arm-linux-gnueabi;; \
			armhf ) export ARCHITECTURE=arm-linux-gnueabihf;; \
			i386 ) export ARCHITECTURE=i486-linux-gnu;; \
			mipsel ) export ARCHITECTURE=mipsel-linux-gnu;; \
			macos ) export ARCHITECTURE=MacOS;; \
			all ) export ARCHITECTURE=all;; \
			*-*-* ) export ARCHITECTURE="$$DEBIAN_ARCH";; \
			* ) export ARCHITECTURE=unknown-linux-gnu;; \
		esac; \
		echo "*** building for $$DEBIAN_ARCH using $$ARCHITECTURE ***"; \
		export DEBIAN_ARCH="$$DEBIAN_ARCH"; \
		make -f $(QuantumSTEP)/System/Sources/Frameworks/mySTEP.make build_deb; \
		done
endif
endif

__dummy__:
	# dummy target to allow for comments while setting more make variables
	
	# override if (stripped) package is build using xcodebuild

ifeq ($(RUN_CMD),)
RUN_CMD := run
endif

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

# add architecture specific CFLAGS

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

ifeq ($(ARCHITECTURE),MacOS)
CFLAGS += -Wno-deprecated-declarations
else
CFLAGS += -rdynamic
endif

CFLAGS += -fsigned-char

HOST_INSTALL_PATH := $(QuantumSTEP)/$(INSTALL_PATH)
## prefix by $ROOT unless starting with //
ifneq ($(findstring //,$(INSTALL_PATH)),//)
TARGET_INSTALL_PATH := $(EMBEDDED_ROOT)/$(INSTALL_PATH)
else
TARGET_INSTALL_PATH := $(INSTALL_PATH)
endif

ifeq ($(ARCHITECTURE),MacOS)
# handle #include <Foundation/Foundation.h>
INCLUDES := -I$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/ $(INCLUDES)
endif

INCLUDES := $(INCLUDES) \
		-I$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/include/freetype2 \
		-I$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"') \
		-I$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"') \
		-I$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE)/Headers | sed "s/ / -I/g"')

ifeq ($(ARCHITECTURE),MacOS)
INCLUDES += -I/opt/local/include -I/opt/local/include/X11 -I/opt/local/include/freetype2
endif

# set up appropriate CFLAGS for $(ARCHITECTURE)

# -Wall
WARNINGS =  -Wno-shadow -Wpointer-arith -Wno-import

DEFINES = -DARCHITECTURE=@\"$(ARCHITECTURE)\" \
		-D__mySTEP__ \
		-DHAVE_MMAP

# add -v to debug include search path issues

CFLAGS := $(CFLAGS) \
		-g -O$(OPTIMIZE) -fPIC \
		$(WARNINGS) \
		$(DEFINES) \
		$(INCLUDES)

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
LEXSRCS := $(filter %.l %.lm,$(XSOURCES))
YACCSRCS := $(filter %.y %.ym,$(XSOURCES))

# sources that drive the compiler
# FIXME: include LEX/YACC?
SRCOBJECTS := $(OBJCSRCS) $(CSRCS)

OBJECTS := $(SRCOBJECTS:%.m=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)
OBJECTS := $(OBJECTS:%.mm=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)
OBJECTS := $(OBJECTS:%.c=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)
OBJECTS := $(OBJECTS:%.cpp=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)
OBJECTS := $(OBJECTS:%.c++=$(TARGET_BUILD_DIR)/$(ARCHITECTURE)/+%.o)

# PHP and shell scripts
PHPSRCS   := $(filter %.php,$(XSOURCES))
SHSRCS   := $(filter %.sh,$(XSOURCES))

# INfo.plist
INFOPLISTS   := $(filter Info%.plist %Info.plist %Info%.plist,$(XSOURCES))

# subprojects
SUBPROJECTS := $(filter %.qcodeproj,$(XSOURCES))

# header files
HEADERSRC := $(filter %.h %.pch,$(XSOURCES))

# additional debian control files
DEBIAN_CONTROL := $(filter %.preinst %.postinst %.prerm %.postrm,$(XSOURCES))

# all sources that are processed specially
PROCESSEDSRC := $(SRCOBJECTS) $(PHPSRCS) $(SHSRCS) $(INFOPLISTS) $(HEADERSRC) $(SUBPROJECTS)

# all remaining selected (re)sources
RESOURCES := $(filter-out $(PROCESSEDSRC),$(XSOURCES))

ifeq ($(PRODUCT_NAME),Foundation)
FMWKS := $(addprefix -l,$(FRAMEWORKS))
else
ifeq ($(PRODUCT_NAME),AppKit)
FMWKS := $(addprefix -l,Foundation $(FRAMEWORKS))
else
ifneq ($(strip $(OBJCSRCS)),)	# any objective C source
ifneq ($(ARCHITECTURE),MacOS)
FMWKS := $(addprefix -l,Foundation AppKit $(FRAMEWORKS))
else
FMWKS := $(addprefix -l,$(FRAMEWORKS))
endif
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

ifneq ($(ARCHITECTURE),MacOS)
LIBRARIES := \
		-Wl,-rpath-link,$(QuantumSTEP)/usr/lib \
		-Wl,-rpath-link,$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/lib \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath-link,/g"') \
		$(LIBRARIES)
else

LIBRARIES := -L/opt/local/lib \
		/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation \
		/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation \
		/System/Library/Frameworks/Security.framework/Versions/Current/Security \
		/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit \
		/System/Library/Frameworks/Cocoa.framework/Versions/Current/Cocoa \
		-Wl,-rpath,$(QuantumSTEP)/usr/lib \
		-Wl,-rpath,$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(ARCHITECTURE)/usr/lib \
		-Wl,-rpath,$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath,/g"') \
		-Wl,-rpath,$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath,/g"') \
		-Wl,-rpath,$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(ARCHITECTURE) | sed "s/ / -Wl,-rpath,/g"') \
		$(LIBRARIES)
endif

ifneq ($(OBJCSRCS)$(FMWKS),)
LIBRARIES += -lobjc -lm
ifneq ($(ARCHITECTURE),MacOS)
LIBRARIES += -lgcc_s
endif
endif

.SUFFIXES : .o .c .cpp .m .lm .ym

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

# FIXME: handle .lm .ym

#
# makefile targets
#

# FIXME: we can't easily specify the build order (e.g. Foundation first, then AppKit and finally Cocoa)

build_subprojects:
ifeq ($(RECURSIVE),true)
	# SUBPROJECTS: $(SUBPROJECTS)
	# RECURSIVE: $(RECURSIVE)
ifneq "$(strip $(SUBPROJECTS))" ""
	for i in $(SUBPROJECTS); \
	do \
		( unset ARCHITECTURE PRODUCT_NAME DEBIAN_DEPENDS DEBIAN_RECOMMENDS DEBIAN_DESCRIPTION DEBIAN_PACKAGE_NAME FRAMEWORKS INCLUDES LIBS INSTALL_PATH PRODUCT_NAME SOURCES WRAPPER_EXTENSION FRAMEWORK_VERSION; cd $$(dirname $$i) && echo Entering directory $$(pwd) && ./$$(basename $$i) || break ; echo Leaving directory $$(pwd) ); \
	done
endif
endif

make_bundle:
# make bundle

make_exec: "$(EXEC)"
# make exec

ifneq ($(PHPONLY),true)
ifneq ($(strip $(SRCOBJECTS)),)
make_binary: "$(BINARY)"
	ls -l "$(BINARY)"
else
make_binary:
	# no sources - no binary
endif
else
make_binary:
	# make PHP only
endif

make_php: bundle
# make PHP
	for PHP in $(PHPSRCS); do \
		if [ -r "$$PHP" ]; then mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php" && php -l "$$PHP" && cp -p "$$PHP" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/"; fi; \
		done

DOXYDIST = "$(QuantumSTEP)/System/Installation/Doxy"

build_doxy:	build/$(PRODUCT_NAME).docset
	# BUILD_DOCUMENTATION: $(BUILD_DOCUMENTATION)
ifeq ($(BUILD_DOCUMENTATION),true)
	- [ -r build/$(PRODUCT_NAME).docset/html/index.html ] && (cd build && $(TAR) cf - $(PRODUCT_NAME).docset) | \
		(mkdir -p $(DOXYDIST) && cd $(DOXYDIST) && rm -rf $(DOXYDIST)/$(PRODUCT_NAME).docset && \
		$(TAR) xf - && \
		( echo "<h1>Quantumstep Framework Documentation</h1>"; \
		  echo "<ul>"; \
		  for f in *.docset; \
		  do BN=$$(basename $$f .docset); \
			echo "<li><a href=\"$$BN.docset/html/classes.html\">$$BN.framework</a></li>"; \
		  done; \
		  echo "<ul>" \
		) >index.html )
endif

# rebuild if any header was changed

build/$(PRODUCT_NAME).docset:	$(HEADERSRC)
ifeq ($(WRAPPER_EXTENSION),framework)
ifeq ($(BUILD_DOCUMENTATION),true)
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
# allow to disable building debian packages

build_deb: make_bundle make_exec make_binary build_debian_packages

build_debian_packages: \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" 

# FIXME: use different /tmp/data subdirectories for each running make
# NOTE: don't include /tmp here to protect against issues after typos

UNIQUE := $(shell mktemp -d -u mySTEP.XXXXXX)
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
	$(TAR) cf - --exclude .DS_Store --exclude .svn --exclude Headers -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf -)
ifneq ($(FILES),)
	# additional files relative to install location
	$(TAR) cf - --exclude .DS_Store --exclude .svn --exclude Headers -C "$(PWD)" $(FILES) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf -)
endif
ifneq ($(DATA),)
	# additional files relative to root
	$(TAR) cf - --exclude .DS_Store --exclude .svn --exclude Headers -C "$(PWD)" $(DATA) | (cd "/tmp/$(TMP_DATA)/" && $(TAR) xvf -)
endif
	# strip all executables down to the minimum
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name $(ARCHITECTURE) ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" -name '*php' -prune -print -exec rm -rf {} ";"
	# FIXME: prune .nib so that they still work
ifeq ($(WRAPPER_EXTENSION),framework)
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)"
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)"
endif
	find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	mkdir -p "/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts" && echo $(DEBIAN_VERSION) >"/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)_@_$(DEBIAN_ARCH).deb"
	$(TAR) cf - --owner 0 --group 0 -C "/tmp/$(TMP_DATA)" . | gzip >/tmp/$(TMP_DATA).tar.gz
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
	$(TAR) cvf - --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) . | gzip >/tmp/$(TMP_CONTROL).tar.gz
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
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf -)
	# strip all executables down so that they can be linked
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name $(ARCHITECTURE) ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" -name '*php' -prune -print -exec rm -rf {} ";"
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)
	find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	mkdir -p /tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts && echo $(DEBIAN_VERSION) >/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dev_@_$(DEBIAN_ARCH).deb
	$(TAR) cf - --owner 0 --group 0 -C /tmp/$(TMP_DATA) . | gzip >/tmp/$(TMP_DATA).tar.gz
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
	$(TAR) cvf - $(DEBIAN_CONTROL) --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) . | gzip >/tmp/$(TMP_CONTROL).tar.gz
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
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf -)
	# strip all executables down so that they can be linked
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name $(ARCHITECTURE) ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" -name '*php' -prune -print -exec rm -rf {} ";"
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)
	# keep symbols find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	mkdir -p /tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts && echo $(DEBIAN_VERSION) >/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dbg_@_$(DEBIAN_ARCH).deb
	$(TAR) cf - --owner 0 --group 0 -C /tmp/$(TMP_DATA) . | gzip >/tmp/$(TMP_DATA).tar.gz
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
	$(TAR) cf - $(DEBIAN_CONTROL) --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) . | gzip >/tmp/$(TMP_CONTROL).tar.gz
	- rm -rf $@
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	ls -l $@
else
	# no debug version
endif

install_local:
ifeq ($(INSTALL),true)
    # INSTALL: $(INSTALL)
	- : ls -l "$(BINARY)" # fails for tools because we are on the outer level and have included an empty $(DEBIAN_ARCHITECTURE) in $(BINARY) and $(PKG)
	- [ -x "$(PKG)/../$(PRODUCT_NAME)" ] && cp -f "$(PKG)/../$(PRODUCT_NAME)" "$(PKG)/$(NAME_EXT)/$(PRODUCT_NAME)" # copy potential MacOS binary
ifeq ($(NAME_EXT),bin)
	- $(TAR) cf - --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p '$(HOST_INSTALL_PATH)' && cd '$(HOST_INSTALL_PATH)' && (pwd; $(TAR) xpvf -))
else
	- $(TAR) cf - --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p '$(HOST_INSTALL_PATH)' && cd '$(HOST_INSTALL_PATH)' && (pwd; $(TAR) xpvf - -U --recursive-unlink))
endif
	# installed on localhost at $(HOST_INSTALL_PATH)
else
	# don't install locally
endif

deploy_remote:
ifeq ($(DEPLOY),true)
    # DEPLOY: $(DEPLOY)
	# deploy remote
	- : ls -l "$(BINARY)" # fails for tools because we are on the outer level and have included an empty $$DEBIAN_ARCHITECTURE in $(BINARY) and $(PKG)
	# FIXME: does not copy $(DATA) and $(FILES)
	- $(DOWNLOAD) -n | while read DEVICE NAME; \
		do \
		$(TAR) cf - --exclude .svn --owner 500 --group 1 -C "$(PKG)" "$(NAME_EXT)" | gzip | $(DOWNLOAD) $$DEVICE "cd; mkdir -p '$(TARGET_INSTALL_PATH)' && cd '$(TARGET_INSTALL_PATH)' && gunzip | tar xpvf -" \
		&& echo installed on $$NAME at $(TARGET_INSTALL_PATH) || echo installation failed on $$NAME; \
		done
	#done
else
	# not deployed
endif

launch_remote:
ifeq ($(DEPLOY),true)
ifeq ($(RUN),true)
ifeq ($(WRAPPER_EXTENSION),app)
    # DEPLOY: $(DEPLOY)
    # RUN: $(RUN)
    # RUN_CMD: $(RUN_CMD)
	# try to launch deployed Application using our local Xquartz as a remote display
	# NOTE: if Xquartz is already running, nolisten_tcp will not be applied!
	#
	# FIXME: how do we know the $(ARCHITECTURE) used to specify the EXECUTABLE_PATH?
	#
	defaults write org.macosforge.xquartz.X11 nolisten_tcp 0; \
	rm -rf /tmp/.X0-lock /tmp/.X11-unix; open -a Xquartz; sleep 5; \
	export DISPLAY=localhost:0.0; [ -x /usr/X11R6/bin/xhost ] && /usr/X11R6/bin/xhost + && \
	RUN_DEVICE=$$($(DOWNLOAD) -r | head -n 1) && \
	[ "$$RUN" ] && $(DOWNLOAD) "$$RUN_DEVICE" \
		"cd; set; export QuantumSTEP=$(EMBEDDED_ROOT); export PATH=\$$PATH:$(EMBEDDED_ROOT)/usr/bin; export LOGNAME=$(LOGNAME); export NSLog=yes; export HOST=\$$(expr \"\$$SSH_CONNECTION\" : '\\(.*\\) .* .* .*'); export DISPLAY=\$$HOST:0.0; set; export EXECUTABLE_PATH=Contents/$(ARCHITECTURE); cd '$(TARGET_INSTALL_PATH)' && $(RUN_CMD) '$(PRODUCT_NAME)' $(RUN_OPTIONS)" \
		|| echo failed to run;
endif
endif
endif

# generic bundle rule

# FIXME: use dependencies to link only if any object file has changed

# replace this my make_binary and make_bundle

# link headers of framework

bundle:
ifeq ($(WRAPPER_EXTENSION),framework)
	- [ ! -L "$(PKG)/$(NAME_EXT)/$(CONTENTS)" -a -d "$(PKG)/$(NAME_EXT)/$(CONTENTS)" ] && rm -rf "$(PKG)/$(NAME_EXT)/$(CONTENTS)" # remove directory
	rm -f "$(PKG)/$(NAME_EXT)/$(CONTENTS)" # remove symlink
	(mkdir -p "$(PKG)/$(NAME_EXT)/Versions/A" && ln -sf $(FRAMEWORK_VERSION) "$(PKG)/$(NAME_EXT)/$(CONTENTS)")	# link Current to -> A
endif

headers:
ifeq ($(WRAPPER_EXTENSION),framework)
ifneq ($(strip $(HEADERSRC)),)
# included header files $(HEADERSRC)
	- (mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" && cp $(HEADERSRC) "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" )	# copy headers
endif
	- (mkdir -p "$(EXEC)/Headers" && rm -f $(HEADERS) && ln -sf ../../Headers "$(HEADERS)")	# link to Headers to find <Framework/File.h>
endif
ifeq ($(ARCHITECTURE),MacOS)
# always use system Foundation/AppKit (headers and frameworks)
	mkdir -p $(TARGET_BUILD_DIR)/$(ARCHITECTURE)
	- for i in Foundation CoreFoundation Security AppKit Cocoa \
		; do rm -f $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/$$i; ln -sf /System/Library/Frameworks/$$i.framework/Versions/Current/Headers $(TARGET_BUILD_DIR)/$(ARCHITECTURE)/$$i \
	  ; done
endif

resources:
ifneq ($(WRAPPER_EXTENSION),)
# included resources $(INFOPLISTS) $(RESOURCES)
ifneq ($(strip $(INFOPLISTS)),)
	- cp $(INFOPLISTS) "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Info.plist"
endif
ifneq ($(strip $(RESOURCES)),)
	- mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources"
#	- cp $(RESOURCES) "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/"  # copy resources
	for resource in $(RESOURCES); \
	do \
	(cd $$(dirname "$$resource") && $(TAR) cf - -h --exclude .DS_Store --exclude .git --exclude .svn $$(basename "$$resource")) | (cd "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" && $(TAR) xvf - ); \
	done
# convert any xib to nib
	find "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" -name '*.xib' -print -exec sh -c 'ibtool --compile "$$(dirname {})/$$(basename {} .xib).nib" "{}"' ';' -delete
endif
endif

"$(BINARY)":: bundle headers $(OBJECTS)
	# link $(SRCOBJECTS) -> $(OBJECTS) -> $(BINARY)
	@mkdir -p "$(EXEC)"
	MACOSX_DEPLOYMENT_TARGET=10.5 $(LD) $(LDFLAGS) -o "$(BINARY)" $(OBJECTS) $(LIBRARIES)
	$(NM) -u "$(BINARY)"
	# linked.
ifeq ($(WRAPPER_EXTENSION),)
ifeq ($(ARCHITECTURE),MacOS)
	- rm -f "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(EXECUTABLE_NAME)"
	- ln -sf "$(ARCHITECTURE)/$(EXECUTABLE_NAME)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(EXECUTABLE_NAME)"	# create link to MacOS version
	# link binary
endif
endif
ifeq ($(WRAPPER_EXTENSION),framework)
	# link shared library for frameworks
	- rm -f "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)/$(EXECUTABLE_NAME)"
ifeq ($(ARCHITECTURE),MacOS)
	- ln -sf "$(ARCHITECTURE)/lib$(EXECUTABLE_NAME).$(SO)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(EXECUTABLE_NAME)"	# create link to MacOS version
else
	- ln -sf "lib$(EXECUTABLE_NAME).$(SO)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(ARCHITECTURE)/$(EXECUTABLE_NAME)"	# create libXXX.so entry for ldconfig
endif
endif

"$(EXEC)":: bundle headers resources
	# make directory for executable
	# SOURCES: $(SOURCES)
	# SRCOBJECTS: $(SRCOBJECTS)
	# OBJCSRCS: $(OBJCSRCS)
	# CSRCS: $(CSRCS)
	# LEXSRCS: $(LEXSRCS)
	# YACCSRCS: $(YACCSRCS)
	# OBJECTS: $(OBJECTS)
	# RESOURCES: $(RESOURCES)
	# HEADERS: $(HEADERSRC)
	# INFOPLISTS: $(INFOPLISTS)
	mkdir -p "$(EXEC)"

# EOF