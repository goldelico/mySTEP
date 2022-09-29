#!/usr/bin/make -f
#
# FIXME: the current directory must be the one that contains the .qcodeproj
#
# easy call: DEPLOY=true RUN=true DEBIAN_RELEASES=stretch DEBIAN_ARCHITECTURES=armhf ./AppKit.qcodeproj
#
ifeq (nil,null)   ## this is to allow for the following text without special comment character considerations
#
# This file is part of mySTEP
#
# You should not edit this file as it affects all projects you will compile!
#
# Copyright, H. Nikolaus Schaller <hns@computer.org>, 2003-2021
# This document is licenced using LGPL
#
# Requires Xcode 3.2 or later
# and XQuartz incl. X11 SDK
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
#  Entries marked with + should be defined by the caller of the .qcodeproj
#  Entries with () are optional
#  Entries with - should not be set
#
#  general setup
#   (*) QuantumSTEP - root of QuantumSTEP - default: /usr/local/QuantumSTEP
#   (-) QUIET - optional prefix "@" to make some commands quiet
QUIET=@
#  sources (input)
#   * SOURCES
#   (*) INCLUDES
#   (*) CFLAGS
#   (+) PROFILING - default: no
#   (*) FRAMEWORKS
#   (*) LIBS
#  compile control
#   (+) NOCOMPILE - default: no
#   (+) BUILT_PRODUCTS_DIR - default: build/Deployment
#   (+) TARGET_BUILD_DIR - default: build/Deployment
#   (+) PHPONLY - build only PHP - default: no
#   (+) RECURSIVE - build subprojects first ("true", "no") - default: no
#   (+) BUILD_FOR_DEPLOYMENT - default: no
#   (+) OPTIMIZE - optimize level - default: s
#   (+) INSPECT - save .i and .S intermediate steps - default: no
#   (+) BUILD_STYLE - default: ?
#   (+) GCC_OPTIMIZATION_LEVEL - default: 0
#   (+) BUILD_DOCUMENTATION - default: no
#   (+) DEBIAN_ARCHITECTURES - default: armel armhf arm64 i386 mipsel
#   (-) DEBIAN_ARCH - used internally
#	(+) DEBIAN_RELEASES - default: all releases defined by depends - or staging
#   (+) DEBIAN_RELEASE - used internally the release to build for (modifies compiler, libs and staging for result)- default: staging
#  bundle definitions (output)
#   * PROJECT_NAME
#   (*) PRODUCT_NAME - the product name (if "All", then PROJECT_NAME is taken)
#   (*) PRODUCT_BUNDLE_IDENTIFIER
#   * WRAPPER_EXTENSION
#   (*) FRAMEWORK_VERSION - default: A
#   (*) CURRENT_PROJECT_VERSION - default: 1.0.0
#   - EXECUTABLE_NAME - (if "All", then PRODUCT_NAME is taken)
#   - TRIPLE - the architecture triple to use
#  Debian packaging (postprocess 1)
#   * DEBIAN_PACKAGE_NAME - default: quantumstep-$PRODUCT_NAME-$WRAPPER-extension
#   - DEBIAN_PACKAGE_VERSION - defult: current date/time
#   (+) DEBDIST - where to store the binary-arch files - default: $QuantumSTEP/System/Installation/Debian/dists
#   (*) DEBIAN_DEPENDS - e.g. quantumstep-cocoa-framework
#   (*) DEBIAN_RECOMMENDS - e.g. quantumstep-cocoa-framework
#   (*) DEBIAN_CONFLICTS -
#   (*) DEBIAN_REPLACES -
#   (*) DEBIAN_PROVIDES -
#   (*) DEBIAN_HOMEPAGE - www.quantum-step.com
#   (*) DEBIAN_DESCRIPTION
#   (*) DEBIAN_MAINTAINER
#   (*) DEBIAN_SECTION - e.g. x11
#   (*) DEBIAN_PRIORITY - e.g. optional
#   (*) DEBIAN_NOPACKAGE - don't build packages
#   (*) FILES - more files to include (e.g. binaries) relative to INSTALL_PATH (deprecated)
#   (*) DATA - more files to include (e.g. binaries) relative to root (deprecated)
#   (*) DEBIAN_RAW_FILES - additional files/directories to be included in debian package
#   (*) DEBIAN_RAW_PREFIX - path prefixed to DEBIAN_RAW_FILES before packing (may be ./) - default:
#   (*) DEBIAN_RAW_SUBDIR - Subdir within sources where we find the raw files - default:
#   (+) OPEN_DEBIAN - if true, open .deb through DebianViewer
#  download and test (postprocess 2)
#   * INSTALL_PATH - install path for compiled SOURCES relative to $QuantumSTEP (or absolute if it starts with //) - default empty
#   - INSTALL
#   (+) EMBEDDED_ROOT - root on embedded device (default /usr/local/QuantumSTEP)
#   (+) DEPLOY - true/false default: false
#   (+) RUN - true/false default: false
#   (+) RUN_CMD - default: run
#
# targets
#   build:		build everything (outer level)
#   build_deb:		called recursively to build for a specific debian architecture
#   clean:		clears build directory (not for subprojects)
#   debug:		print all variable

endif

# makefile debug hack https://www.cmcrossroads.com/article/tracing-rule-execution-gnu-make

ifeq (yes,no)
OLD_SHELL := $(SHELL)
SHELL = $(warning Building $@)$(OLD_SHELL)
endif

# don't compile for MacOS (but copy/install) if called as build script phase from within Xcode

ifneq ($(XCODE_VERSION_ACTUAL),)
NOCOMPILE:=true
endif

ifeq ($(QuantumSTEP),)
QuantumSTEP:=/usr/local/QuantumSTEP
endif

ifeq ($(EMBEDDED_ROOT),)
EMBEDDED_ROOT:=$(QuantumSTEP)
endif

ifeq ($(INSTALL),)
INSTALL:=true
endif

HOST_INSTALL_PATH := $(QuantumSTEP)/$(INSTALL_PATH)
# prefix by $EMBEDDED_ROOT unless $INSTALL_PATH is starting with //
ifneq ($(findstring //,$(INSTALL_PATH)),//)
TARGET_INSTALL_PATH := $(EMBEDDED_ROOT)/$(INSTALL_PATH)
else
TARGET_INSTALL_PATH := $(INSTALL_PATH)
# don't install on localhost
INSTALL=false
endif

include $(QuantumSTEP)/System/Sources/Frameworks/Version.def

.PHONY:	clean debug build prepare_temp_files build_deb build_architectures build_subprojects build_doxy make_sh install_local deploy_remote launch_remote bundle headers resources

# configure Embedded System if undefined

ROOT:=$(QuantumSTEP)

### FIXME: what is the right path???

# FIXME: this does only work on the Mac! On embedded the qsrsh is in /usr/bin/$HOST_ARCH or $PATH
DOWNLOAD_TOOL := $(QuantumSTEP)/usr/bin/qsrsh
XHOST_TOOL := /opt/X11/bin/xhost
# tools
ifeq ($(shell uname),Darwin)
# use platform specific (cross-)compiler on Darwin host
DOXYGEN := /Applications/Doxygen.app/Contents/Resources/doxygen
# disable special MacOS X stuff for tar
TAR := COPY_EXTENDED_ATTRIBUTES_DISABLED=true COPYFILE_DISABLE=true /opt/local/bin/gnutar
# we want tar to save root:root and not 0:0 (translated on MacOS)
ROOT=root

ifeq ($(PRODUCT_NAME),All)
# Xcode aggregate target
PRODUCT_NAME=$(PROJECT_NAME)
endif

ifeq ($(PRODUCT_BUNDLE_IDENTIFIER),)
PRODUCT_BUNDLE_IDENTIFIER=org.quantumstep.$(PRODUCT_NAME)
endif

ifeq ($(TRIPLE),php)
# besser: php -l & copy
CC := : php -l + copy
# besser: makephar - (shell-funktion?)
LD := : makephar
AS := :
NM := :
STRIP := :
SO := phar
PHAR := /usr/bin/phar
else ifeq ($(TRIPLE),MacOS)
DEFINES += -D__mySTEP__
INCLUDES += -I/opt/local/include -I/opt/local/include/X11 -I/opt/local/include/freetype2 -I/opt/local/lib/libffi-3.2.1/include
TOOLCHAIN=/usr/bin
CC := MACOSX_DEPLOYMENT_TARGET=10.6 $(TOOLCHAIN)/gcc
LD := $(CC)
AS := $(TOOLCHAIN)/as
NM := $(TOOLCHAIN)/nm
STRIP := $(TOOLCHAIN)/strip
SO := dylib
else ifeq ($(TRIPLE),arm-iPhone-darwin)
TOOLCHAIN=/Developer/Platforms/iPhoneOS.platform/Developer/usr
CC := $(TOOLCHAIN)/bin/arm-apple-darwin9-gcc-4.0.1
LD := $(CC)
AS := $(TOOLCHAIN)/as
NM := $(TOOLCHAIN)/nm
STRIP := $(TOOLCHAIN)/strip
SO := dylib
else
DEFINES += -D__mySTEP__
# use specific toolchain depending on DEBIAN_RELEASE (wheezy, jessie, stretch, buster, bullseye, ...) and DEBIAN_ARCH (arm64, armhf, mipsel, ...)
# this is the default compiler/toolchain we use for "universal" apps/bundles
TOOLCHAIN_FALLBACK = 8-Jessie
DEBIAN_RELEASE_FALLBACK = jessie
DEBIAN_RELEASE_TRANSLATED=${shell case "$(DEBIAN_RELEASE)" in \
	( etch ) echo "4-Etch";; \
	( lenny ) echo "5-Lenny";; \
	( squeeze ) echo "6-Squeeze";; \
	( wheezy ) echo "7-Wheezy";; \
	( jessie ) echo "8-Jessie";; \
	( stretch ) echo "9-Stretch";; \
	( buster ) echo "10-Buster";; \
	( bullseye ) echo "11-Bullseye";; \
	( bookworm ) echo "12-Bookworm";; \
	( trixie ) echo "13-Trixie";; \
	( * ) echo "$(TOOLCHAIN_FALLBACK)";; \
	esac;}
# FIXME: should check if toolchain is installed...
TOOLCHAIN := $(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/Current/$(DEBIAN_RELEASE_TRANSLATED)/$(DEBIAN_ARCH)/usr
CC := LANG=C $(TOOLCHAIN)/bin/$(TRIPLE)-gcc
# CC := clang -march=armv7-a -mfloat-abi=soft -ccc-host-triple $(TRIPLE) -integrated-as --sysroot $(QuantumSTEP) -I$(QuantumSTEP)/include
LD := $(CC) -v -L$(TOOLCHAIN)/$(TRIPLE)/lib -Wl,-rpath-link,$(TOOLCHAIN)/$(TRIPLE)/lib
AS := $(TOOLCHAIN)/bin/$(TRIPLE)-as
NM := $(TOOLCHAIN)/bin/$(TRIPLE)-nm
STRIP := $(TOOLCHAIN)/bin/$(TRIPLE)-strip
SO := so
endif

else # Darwin

# native compile on target machine
DOXYGEN := doxygen
TAR := tar
## FIXME: allow to cross-compile
TOOLCHAIN := native
INCLUDES += -I/usr/include/freetype2
CC := $(TRIPLE)-gcc
LD := $(CC) -v
AS := $(TRIPLE)-as
NM := $(TRIPLE)-nm
STRIP := $(TRIPLE)-strip
SO := so
endif

# if we call the makefile not within Xcode
ifeq ($(BUILT_PRODUCTS_DIR),)
BUILT_PRODUCTS_DIR=build/Deployment
endif
ifeq ($(TARGET_BUILD_DIR),)
TARGET_BUILD_DIR=build/Deployment
endif
ifeq ($(DEBIAN_RELEASE),none)
TTT=$(TARGET_BUILD_DIR)/$(TRIPLE)/
else
TTT=$(TARGET_BUILD_DIR)/$(DEBIAN_RELEASE)/$(TRIPLE)/
endif

# define CONTENTS subdirectory as expected by the Foundation library

ifeq ($(EXECUTABLE_NAME),All)
EXECUTABLE_NAME=$(PRODUCT_NAME)
endif
ifeq ($(EXECUTABLE_NAME),)
EXECUTABLE_NAME=$(PRODUCT_NAME)
endif

STDCFLAGS := $(CFLAGS) -std=gnu99

ifeq ($(WRAPPER_EXTENSION),)	# command line tool
	CONTENTS=.
	# shared between all binary tools
	NAME_EXT=bin
	# this keeps the binaries separated for installation/packaging
	PKG=$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).bin
	EXEC=$(PKG)/$(NAME_EXT)/$(TRIPLE)
ifeq ($(DEBIAN_RELEASE),none)
	BINARY=$(EXEC)/$(PRODUCT_NAME)
else
ifeq ($(DEBIAN_RELEASE),staging)	# generic command line tool
	BINARY=$(EXEC)/$(PRODUCT_NAME)
else	# release specific
	BINARY=$(EXEC)/$(PRODUCT_NAME)-$(DEBIAN_RELEASE)
endif
endif
	# architecture specific version (only if it does not yet have the prefix)
ifneq (,$(findstring ///System/Library/Frameworks/System.framework/Versions/$(TRIPLE),//$(INSTALL_PATH)))
	INSTALL_PATH := /System/Library/Frameworks/System.framework/Versions/$(TRIPLE)$(INSTALL_PATH)
endif
else
ifeq ($(WRAPPER_EXTENSION),framework)	# framework
ifeq ($(FRAMEWORK_VERSION),)	# empty
	# default
	FRAMEWORK_VERSION=A
endif
ifeq ($(CURRENT_PROJECT_VERSION),)	# empty
# default
CURRENT_PROJECT_VERSION=1.0.0
endif
	CONTENTS=Versions/Current
	NAME_EXT=$(PRODUCT_NAME).$(WRAPPER_EXTENSION)
	PKG=$(BUILT_PRODUCTS_DIR)
	EXEC=$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)
ifeq ($(DEBIAN_RELEASE),none)
	BINARY=$(EXEC)/lib$(EXECUTABLE_NAME).$(SO)
else
ifeq ($(DEBIAN_RELEASE),staging)	# generic command line tool
	BINARY=$(EXEC)/lib$(EXECUTABLE_NAME).$(SO)
else	# release specific
	BINARY=$(EXEC)/lib$(EXECUTABLE_NAME)-$(DEBIAN_RELEASE).$(SO)
endif
endif
#	HEADERS=$(EXEC)/Headers/$(PRODUCT_NAME)
	STDCFLAGS := -I$(EXEC)/../Headers/ $(STDCFLAGS)
ifeq ($(TRIPLE),MacOS)
	LDFLAGS := -dynamiclib -install_name $(HOST_INSTALL_PATH)/$(NAME_EXT)/Versions/Current/$(PRODUCT_NAME) -undefined dynamic_lookup $(LDFLAGS)
else
	LDFLAGS := -shared -Wl,-soname,$(PRODUCT_NAME) $(LDFLAGS)
endif
else
	CONTENTS=Contents
	NAME_EXT=$(PRODUCT_NAME).$(WRAPPER_EXTENSION)
	PKG=$(BUILT_PRODUCTS_DIR)
	EXEC=$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)
ifeq ($(DEBIAN_RELEASE),none)
	BINARY=$(EXEC)/$(EXECUTABLE_NAME)
else
ifeq ($(DEBIAN_RELEASE),staging)	# generic app or command line tool
	BINARY=$(EXEC)/$(EXECUTABLE_NAME)
else	# release specific
	BINARY=$(EXEC)/$(EXECUTABLE_NAME)-$(DEBIAN_RELEASE)
endif
endif
ifeq ($(WRAPPER_EXTENSION),app)
#	STDCFLAGS := -DFAKE_MAIN $(STDCFLAGS)	# application
else
ifeq ($(TRIPLE),MacOS)
	LDFLAGS := -dynamiclib -install_name @rpath/$(NAME_EXT)/Versions/Current/MacOS/$(PRODUCT_NAME) -undefined dynamic_lookup $(LDFLAGS)
else
	LDFLAGS := -shared -Wl,-soname,$(NAME_EXT) $(LDFLAGS)	# any other bundle
endif
endif
endif
endif

# expand patterns in SOURCES (feature is not used by QuantumCode)
XSOURCES := $(wildcard $(SOURCES))

# get the objects from all sources we need to compile and link
OBJCSRCS   := $(filter %.m %.mm,$(XSOURCES))
CSRCS   := $(filter %.c %.cpp %.c++,$(XSOURCES))
LEXSRCS := $(filter %.l %.lm,$(XSOURCES))
YACCSRCS := $(filter %.y %.ym,$(XSOURCES))

# sources that drive the compiler
# FIXME: include LEX/YACC?
SRCOBJECTS := $(OBJCSRCS) $(CSRCS)

OBJECTS := $(SRCOBJECTS:%.m=$(TTT)+%.o)
OBJECTS := $(OBJECTS:%.mm=$(TTT)+%.o)
OBJECTS := $(OBJECTS:%.c=$(TTT)+%.o)
OBJECTS := $(OBJECTS:%.cpp=$(TTT)+%.o)
OBJECTS := $(OBJECTS:%.c++=$(TTT)+%.o)

# PHP and shell scripts
PHPSRCS   := $(filter %.php,$(XSOURCES))
PHPOBJECTS := $(PHPSRCS:%.php=$(TTT)+%.o)
SHSRCS   := $(filter %.sh,$(XSOURCES))

# INfo.plist
INFOPLISTS   := $(filter Info%.plist %Info.plist %Info%.plist,$(XSOURCES))

# subprojects
SUBPROJECTS := $(filter %.qcodeproj,$(XSOURCES))

# header files
HEADERSRC := $(filter %.h %.pch,$(XSOURCES))

# additional debian control files
DEBIAN_CONTROL := $(filter %.preinst %.postinst %.prerm %.postrm %.conffiles,$(XSOURCES))

# all sources that are processed specially
PROCESSEDSRC := $(SRCOBJECTS) $(PHPSRCS) $(SHSRCS) $(INFOPLISTS) $(HEADERSRC) $(SUBPROJECTS)

# all remaining selected (re)sources
RESOURCES := $(filter-out $(PROCESSEDSRC),$(XSOURCES))

# default is to build for all

ifeq ($(PHPONLY),true)
BASE_OS_LIST=
else
BASE_OS_LIST=MacOS Debian
endif
ifneq ($(strip $(PHPSRCS)),)	# and any PHP source
BASE_OS_LIST+=php
endif

ifeq ($(DEBIAN_ARCHITECTURES),)
DEBIAN_ARCHITECTURES=armel armhf arm64 i386 mipsel
# ifeq ($(RUN),true)
# take only the arch of the "run device"
endif

# recursively make for all architectures $(DEBIAN_ARCHITECTURES) and RELEASES as defined in DEBIAN_DEPENDS
ifeq ($(DEBIAN_RELEASES),)
DEBIAN_RELEASES=$(shell echo "$(DEBIAN_DEPENDS)" "$(DEBIAN_RECOMMENDS) $(DEBIAN_CONFLICTS) $(DEBIAN_REPLACES) $(DEBIAN_PROVIDES)" | tr ',' '\n' | fgrep ':' | sed 's/ *\(.*\):.*/\1/g' | sort -u)
endif
ifeq ($(DEBIAN_RELEASES),)
DEBIAN_RELEASES="staging"
endif

# this is the default/main target on the outer level

ifeq ($(NOCOMPILE),true)
build:	build_subprojects build_doxy install_local
else
build:	build_subprojects build_doxy build_architectures deploy_remote launch_remote
endif
	@date

clean:
ifeq ($(RECURSIVE),true)
# SUBPROJECTS: $(SUBPROJECTS)
# RECURSIVE: $(RECURSIVE)
ifneq "$(strip $(SUBPROJECTS))" ""
	@for i in $(SUBPROJECTS); \
	do \
( unset TRIPLE PRODUCT_NAME DEBIAN_DEPENDS DEBIAN_RECOMMENDS DEBIAN_DESCRIPTION DEBIAN_PACKAGE_NAME FRAMEWORKS INCLUDES LIBS INSTALL_PATH PRODUCT_NAME SOURCES WRAPPER_EXTENSION FRAMEWORK_VERSION; export RECURSIVE; cd $$(dirname $$i) && echo Entering directory $$(pwd) && ./$$(basename $$i) clean || break ; echo Leaving directory $$(pwd) ); \
	done
endif
endif
	@[ -d build ] && chmod -Rf u+w build || true	# rm -rf refuses to delete files without write mode
	@rm -rf build
	@echo CLEAN

debug:	# see http://www.oreilly.com/openbook/make3/book/ch12.pdf
	$(for v,$(V), \
	$(warning $v = $($v)))

###
### copy/install $DATA and $FILES and $DEBIAN_RAW_FILES $DEBIAN_RAW_PATH $DEBIAN_RAW_SUBDIR
### build_deb (only)
### architecture all-packages are part of machine specific Packages.gz (!)
### there is not necessarily a special binary-all directory but we can do that

### FIXME: directly use the DEBIAN_ARCH names for everything

build_architectures:
	@echo build_architectures
ifneq ($(DEBIAN_ARCHITECTURES),none)
ifneq ($(DEBIAN_ARCHITECTURES),)
# ifeq ($(RUN),true)
# take only the release of the RUN device
	echo DEBIAN_RELEASES: $(DEBIAN_RELEASES); \
	for BASE_OS in $(BASE_OS_LIST); do \
	if [ "$$BASE_OS" = "Debian" ]; then \
	for DEBIAN_RELEASE in $(DEBIAN_RELEASES); do \
		for DEBIAN_ARCH in $(DEBIAN_ARCHITECTURES); do \
			EXIT=1; \
			case "$$DEBIAN_ARCH" in \
			armel ) export TRIPLE=arm-linux-gnueabi;; \
			armhf ) export TRIPLE=arm-linux-gnueabihf;; \
			arm64 ) export TRIPLE=aarch64-linux-gnu;; \
			i386 ) export TRIPLE=i486-linux-gnu;; \
			amd64 ) export TRIPLE=x86_64-linux-gnu;; \
			mipsel ) export TRIPLE=mipsel-linux-gnu;; \
			*-*-* ) export TRIPLE="$$DEBIAN_ARCH";; \
			* ) export TRIPLE=unknown-linux-gnu;; \
		esac; \
		echo "*** building for $$DEBIAN_RELEASE / $$DEBIAN_ARCH using $$TRIPLE ***"; \
		export DEBIAN_RELEASE="$$DEBIAN_RELEASE"; \
		export DEBIAN_ARCH="$$DEBIAN_ARCH"; \
		export TRIPLE="$$TRIPLE"; \
		$(QUIET)make -f $(QuantumSTEP)/System/Sources/Frameworks/mySTEP.make build_deb; \
		echo "$$DEBIAN_ARCH" done; \
		done ;\
	echo "$$DEBIAN_RELEASE" done; \
	done; \
	else \
		export DEBIAN_RELEASE="none"; \
		export DEBIAN_ARCH="none"; \
		export TRIPLE=$$BASE_OS; \
		EXIT=0; \
		echo "*** building for $$BASE_OS ***"; \
		$(QUIET)make -f $(QuantumSTEP)/System/Sources/Frameworks/mySTEP.make build_deb; \
		echo "$$BASE_OS" done; \
	fi; \
	$(QUIET)make -f $(QuantumSTEP)/System/Sources/Frameworks/mySTEP.make make_sh install_local; \
done
endif
endif
	@echo build_architectures done

__dummy__:
	# dummy target to allow for comments while setting more make variables
	
ifeq ($(RUN_CMD),)
# override if (stripped) package is built using xcodebuild
RUN_CMD := run
endif

# add default frameworks
ifeq ($(PRODUCT_NAME).$(WRAPPER_EXTENSION),Foundation.framework)
# none to add if we build Foundation.framework
else ifeq ($(PRODUCT_NAME).$(WRAPPER_EXTENSION),AppKit.framework)
# add Foundation if we build AppKit.framework
FRAMEWORKS := Foundation $(FRAMEWORKS)
else
# always add Foundation.framework and AppKit.framework
FRAMEWORKS := Foundation AppKit CoreData Cocoa $(FRAMEWORKS)
endif

INCLUDES += -I$(TOOLCHAIN)/$(TRIPLE)/include/freetype2

ifeq ($(TRIPLE),MacOS)
LNK :=
else
LNK := .link
endif

# allow to use #import <framework/header.h> while building the framework
INCLUDES := -I$(TTT) -I$(EXEC)/../Headers$(LNK) $(INCLUDES)

ifneq ($(strip $(OBJCSRCS)),)	# any objective C source
ifeq ($(TRIPLE),MacOS)
# check if each framework exists in /System/Library/*Frameworks or explicitly include/link from $(QuantumSTEP)
### FIXME: why do we need this? MacOS only...
### MacOS should use -F and the framework path!
INCLUDES := $(INCLUDES) $(shell for FMWK in CoreFoundation $(FRAMEWORKS); \
	do \
	if [ -d /System/Library/Frameworks/$${FMWK}.framework ]; \
	then :; \
	elif [ -d $(QuantumSTEP)/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/Library/Frameworks/$$FMWK.framework/Versions/Current/Headers; \
	elif [ -d $(QuantumSTEP)/System/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/System/Library/Frameworks/$$FMWK.framework/Versions/Current/Headers; \
	elif [ -d $(QuantumSTEP)/System/Library/PrivateFrameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/System/Library/PrivateFrameworks/$$FMWK.framework/Versions/Current/Headers; \
	elif [ -d $(QuantumSTEP)/Developer/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/Developer/Library/Frameworks/$$FMWK.framework/Versions/Current/Headers; \
	else echo -I$$FMWK.headers; \
	fi; done)

### FIXME: why do we need this? MacOS only...
LIBS := $(LIBS) $(shell for FMWK in CoreFoundation $(FRAMEWORKS); \
	do \
	if [ -d /System/Library/Frameworks/$${FMWK}.framework ]; \
	then echo -framework $$FMWK; \
	elif [ -d $(QuantumSTEP)/Library/Frameworks/$$FMWK.framework ]; \
	then echo $(QuantumSTEP)/Library/Frameworks/$$FMWK.framework/Versions/Current/$(TRIPLE)/lib$$FMWK.dylib; \
	elif [ -d $(QuantumSTEP)/System/Library/Frameworks/$$FMWK.framework ]; \
	then echo $(QuantumSTEP)/System/Library/Frameworks/$$FMWK.framework/Versions/Current/$(TRIPLE)/lib$$FMWK.dylib; \
	elif [ -d $(QuantumSTEP)/System/Library/PrivateFrameworks/$$FMWK.framework ]; \
	then echo $(QuantumSTEP)/System/Library/PrivateFrameworks/$$FMWK.framework/Versions/Current/$(TRIPLE)/lib$$FMWK.dylib; \
	elif [ -d $(QuantumSTEP)/Developer/Library/Frameworks/$$FMWK.framework ]; \
	then echo $(QuantumSTEP)/Developer/Library/Frameworks/$$FMWK.framework/Versions/Current/$(TRIPLE)/lib$$FMWK.dylib; \
	else echo lib$$FMWK.dylib; \
	fi; done)
else
# look up headers and libs to link
INCLUDES := $(INCLUDES) $(shell for FMWK in $(FRAMEWORKS); \
	do \
	if [ -d $(QuantumSTEP)/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/Library/Frameworks/$$FMWK.framework/Versions/Current/Headers$(LNK); \
	elif [ -d $(QuantumSTEP)/System/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/System/Library/Frameworks/$$FMWK.framework/Versions/Current/Headers$(LNK); \
	elif [ -d $(QuantumSTEP)/System/Library/PrivateFrameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/System/Library/PrivateFrameworks/$$FMWK.framework/Versions/Current/Headers$(LNK); \
	elif [ -d $(QuantumSTEP)/Developer/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/Developer/Library/Frameworks/$$FMWK.framework/Versions/Current/Headers$(LNK); \
	else echo -I$$FMWK$(LNK); \
	fi; done)

### hier fehlt vermutlich noch der rlink-path!

FMWKS := $(FMWKS) $(shell for FMWK in $(FRAMEWORKS); \
	do \
	for DIR in $(QuantumSTEP)/Library/Frameworks $(QuantumSTEP)/System/Library/Frameworks $(QuantumSTEP)/System/Library/PrivateFrameworks $(QuantumSTEP)/Developer/Library/Frameworks; \
		do \
		if [ -r $$DIR/$$FMWK.framework/Versions/Current/$(TRIPLE)/lib$$FMWK-$(DEBIAN_RELEASE).so ]; \
		then echo $$DIR/$$FMWK.framework/Versions/Current/$(TRIPLE)/lib$$FMWK-$(DEBIAN_RELEASE).so; \
		elif [ -r $$DIR/$$FMWK.framework/Versions/Current/$(TRIPLE)/lib$$FMWK-$(DEBIAN_RELEASE_FALLBACK).so ]; \
		then echo $$DIR/$$FMWK.framework/Versions/Current/$(TRIPLE)/lib$$FMWK-$(DEBIAN_RELEASE_FALLBACK).so; \
		elif [ -L $$DIR/$$FMWK.framework/Versions/Current/$(TRIPLE)/$$FMWK ]; \
		then echo $$DIR/$$FMWK.framework/Versions/Current/$(TRIPLE)/$$FMWK; \
		fi; \
		done; \
	done)

# FMWKS := $(addprefix -l ,$(FRAMEWORKS))
endif
endif

ifeq ($(TRIPLE),MacOS)
LIBRARIES := \
		$(FMWKS) \
		$(LIBS)
else ifeq ($(TRIPLE),php)
# nothing
else
LIBRARIES := \
		-Wl,-rpath-link,$(QuantumSTEP)/usr/lib \
		-Wl,-rpath-link,$(TOOLCHAIN)/lib \
		-L$(QuantumSTEP)/usr/lib \
		-L$(TOOLCHAIN)/lib

LIBRARIES += $(FMWKS) $(LIBS)

# FIXME: do we still need this?
ifneq ($(OBJCSRCS)$(FMWKS),)
LIBRARIES += -lgcc_s
endif

endif

ifneq ($(OBJCSRCS)$(FMWKS),)
LIBRARIES += -lobjc -lm
endif

# setup gcc

.SUFFIXES : .o .c .cpp .m .lm .ym

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
ifeq ($(TRIPLE),arm-linux-gnueabi)
OPTIMIZE := 3
STDCFLAGS += -fno-section-anchors -ftree-vectorize -mfpu=neon -mfloat-abi=softfp
endif
ifeq ($(TRIPLE),arm-linux-gnueabihf)
OPTIMIZE := 3
# we could try -mfloat-abi=hardfp
# see https://wiki.linaro.org/Linaro-arm-hardfloat
STDCFLAGS += -fno-section-anchors -ftree-vectorize # -mfpu=neon -mfloat-abi=hardfp
endif

ifeq ($(TRIPLE),MacOS)
STDCFLAGS += -Wno-deprecated-declarations
else
STDCFLAGS += -rdynamic
endif

STDCFLAGS += -fsigned-char

# set up appropriate STDCFLAGS for $(TRIPLE)

# -Wall
WARNINGS =  -Wno-shadow -Wpointer-arith -Wno-import

# define as Objective-C string so that NSBundle knows it for finding the correct subdirectory
DEFINES += -DARCHITECTURE=@\"$(TRIPLE)\"
DEFINES += -DHAVE_MMAP

# add -v to debug include search path issues
STDCFLAGS += -g -fPIC -O$(OPTIMIZE) $(WARNINGS) $(DEFINES) $(INCLUDES)

ifeq ($(PROFILING),YES)
STDCFLAGS := -pg $(STDCFLAGS)
endif

# ifeq ($(GCC_WARN_ABOUT_MISSING_PROTOTYPES),YES)
# STDCFLAGS :=  -Wxyz $(STDCFLAGS)
# endif

# should be solved differently
ifneq ($(TRIPLE),arm-zaurus-linux-gnu)
OBJCFLAGS := $(STDCFLAGS) -fconstant-string-class=NSConstantString -D_NSConstantStringClassName=NSConstantString
endif

# define rules for .SUFFIXES

# adding /+ to the file path looks strange but is to avoid problems with ../neighbour/source.m
# if someone knows how to easily substitute ../ by ++/ or .../ in TARGET_BUILD_DIR we could avoid some other minor problems
# FIXME: please use $(subst ...)

$(TTT)+%.o: %.m
	@- mkdir -p $(TTT)+$(*D)
	# compile $< -> $*.o
	if ! $(CC) -v 2>/dev/null; then echo "can't find $(CC)"; false; fi
ifeq ($(INSPECT),true)
	$(QUIET)$(CC) -c $(OBJCFLAGS) -E $< -o $(TTT)+$*.i	# store preprocessor result for debugging
	$(QUIET)$(CC) -c $(OBJCFLAGS) -S $< -o $(TTT)+$*.S	# store assembler source for debugging
endif
	$(QUIET)$(CC) -c $(OBJCFLAGS) $< -o $(TTT)+$*.o

$(TTT)+%.o: %.c
	@- mkdir -p $(TTT)+$(*D)
	# compile $< -> $*.o
	if ! $(CC) -v 2>/dev/null; then echo "can't find $(CC)"; false; fi
	$(QUIET)$(CC) -c $(STDCFLAGS) $< -o $(TTT)+$*.o

$(TTT)+%.o: %.cpp
	@- mkdir -p $(TTT)+$(*D)
	# compile $< -> $*.o
	if ! $(CC) -v 2>/dev/null; then echo "can't find $(CC)"; false; fi
	$(QUIET)$(CC) -c $(STDCFLAGS) $< -o $(TTT)+$*.o

$(TTT)+%.o: %.php
	@- mkdir -p $(TTT)+$(*D)
	php -l $< && php -w $< >$(TTT)+$*.o

# FIXME: handle .lm .ym

#
# makefile targets
#

# FIXME: we can't easily specify the build order (e.g. Foundation first, then AppKit and finally Cocoa)

build_subprojects:
	# DEBIAN_ARCHITECTURES: $(DEBIAN_ARCHITECTURES)
	# DEBIAN_ARCH: $(DEBIAN_ARCH)
	# PROJECT_NAME: $(PROJECT_NAME)
	# PRODUCT_NAME: $(PRODUCT_NAME)
	# FRAMEWORK_VERSION: $(FRAMEWORK_VERSION)
	# WRAPPER_EXTENSION: $(WRAPPER_EXTENSION)
ifeq ($(RECURSIVE),true)
	# SUBPROJECTS: $(SUBPROJECTS)
	# RECURSIVE: $(RECURSIVE)
ifneq "$(strip $(SUBPROJECTS))" ""
	for i in $(SUBPROJECTS); \
	do \
		( unset TRIPLE PRODUCT_NAME DEBIAN_DEPENDS DEBIAN_RECOMMENDS DEBIAN_DESCRIPTION DEBIAN_PACKAGE_NAME FRAMEWORKS INCLUDES LIBS INSTALL_PATH PRODUCT_NAME SOURCES WRAPPER_EXTENSION FRAMEWORK_VERSION; cd $$(dirname $$i) && echo Entering directory $$(pwd) && ./$$(basename $$i) $(SUBCMD) || break ; echo Leaving directory $$(pwd) ); \
	done
endif
endif

make_bundle:
	# make bundle
	# DEBIAN_RELEASE: $(DEBIAN_RELEASE)
	# DEBIAN_ARCH: $(DEBIAN_ARCH)
	# DEBIAN_PACKAGE_NAME: $(DEBIAN_PACKAGE_NAME)
	# TRIPLE: $(TRIPLE)
	# EXEC: $(EXEC)
	# BINARY: $(BINARY)
	# PKG/NAME_EXT/CONTENTS: $(PKG)/$(NAME_EXT)/$(CONTENTS)

make_exec: "$(EXEC)"
	# make exec

make_binary: make_exec "$(BINARY)"
	$(QUIET) [ -f "$(BINARY)" ] && ls -l "$(BINARY)" || true

make_sh: bundle
	@echo make_sh
	# SHSRCS: $(SHSRCS)
	$(QUIET)for SH in $(SHSRCS); do \
		mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" && \
		chmod -Rf u+w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" && \
		cp -pf "$$SH" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" && \
		chmod -R a-w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/"; \
	done
	@echo make_sh done

DOXYDIST = "$(QuantumSTEP)/System/Installation/Doxy"

build_doxy:	build/$(PRODUCT_NAME).docset
	# BUILD_DOCUMENTATION: $(BUILD_DOCUMENTATION)
ifeq ($(BUILD_DOCUMENTATION),true)
	$(QUIET)- rsync -vaz ~/bk ~/test
	$(QUIET)- true && [ -r build/$(PRODUCT_NAME).docset/html/index.html ] && rsync -avz $(PRODUCT_NAME).docset $(DOXYDIST)/ && \
		( echo "<h1>Quantumstep Framework Documentation</h1>"; \
		  echo "<ul>"; \
	      for f in *.docset; \
	      do BN=$$(basename $$f .docset); \
		    echo "<li><a href=\"$$BN.docset/html/classes.html\">$$BN.framework</a></li>"; \
	      done; \
	      echo "<ul>" \
	    ) >index.html )

	$(QUIET)- false && [ -r build/$(PRODUCT_NAME).docset/html/index.html ] && (cd build && $(TAR) cf - $(PRODUCT_NAME).docset) | \
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
	$(QUIET)mkdir -p build
	$(QUIET)- $(DOXYGEN) -g build/$(PRODUCT_NAME).doxygen
	$(QUIET)pwd
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
	$(QUIET)- $(DOXYGEN) build/$(PRODUCT_NAME).doxygen && touch $@
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

ifneq ($(strip $(PHPSRCS)),)	# any PHP source
ifeq ($(DEBIAN_DESCRIPTION),)
DEBIAN_DESCRIPTION := part of QuantumSTEP Cloud Framework
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
ifeq ($(DEBIAN_PACKAGE_VERSION),)
DEBIAN_PACKAGE_VERSION := 0.$(shell date '+%Y%m%d%H%M%S' )
endif
ifeq ($(DEBIAN_RELEASE),)
DEBIAN_RELEASE := staging
endif
ifeq ($(DEBDIST),)
DEBDIST="$(QuantumSTEP)/System/Installation/Debian/dists/$(DEBIAN_RELEASE)/main"
endif

# FIXME: allow to disable -dev and -dbg if we are marked "private"
# allow to disable building debian packages

build_deb: make_bundle bundle make_binary build_debian_packages
	@echo build_deb done

ifeq ($(DEBIAN_NOPACKAGE),)
ifneq ($(DEBIAN_ARCH),none)
ifneq ($(DEBIAN_ARCH),php)
# sequence is important because packages get stripped down in each stage
build_debian_packages: prepare_temp_files \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb"
else	# $(DEBIAN_ARCH),php
build_debian_packages: prepare_temp_files \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb"
endif	# $(DEBIAN_ARCH),php
	# debian_packages
	# DEBIAN_ARCH=$(DEBIAN_ARCH)
	# TRIPLE=$(TRIPLE)
	@echo build_debian_packages done
else
build_debian_packages:
	@echo no architecture for debian packages
endif	# $(DEBIAN_ARCH),none
else	# DEBIAN_NOPACKAGE
build_debian_packages:
	@echo packing_debian_packages skipped
endif

# FIXME: use different /tmp/data subdirectories for each running make
# NOTE: don't include /tmp here to protect against issues after typos

UNIQUE := $(shell mktemp -d -u mySTEP.XXXXXX)
TMP_DATA := $(UNIQUE)/data
TMP_CONTROL := $(UNIQUE)/control
TMP_DEBIAN_BINARY := $(UNIQUE)/debian-binary

prepare_temp_files:
	# prepare temp files in $(TMP_DATA) and $(TMP_CONTROL) using $(TRIPLE) and $(DEBIAN_ARCH)
	chmod -Rf u+w "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)" 2>/dev/null || true
	rm -rf "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)"
	mkdir -p "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)"
#	if [ -d "$(PKG)" ] ; then $(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf -) ; fi
	if [ -d "$(PKG)" ] ; then rsync -avz --exclude .DS_Store --exclude .svn "$(PKG)/$(NAME_EXT)" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)"; fi
ifneq ($(FILES),)
	# additional files relative to install location
	echo FILES is obsolete
	exit 1
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PWD)" $(FILES) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf -)
endif
ifneq ($(DATA),)
	# additional files relative to root $(DATA)
	echo DATA is obsolete
	exit 1
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PWD)" $(DATA) | (cd "/tmp/$(TMP_DATA)/" && $(TAR) xvf -)
endif
ifneq ($(DEBIAN_RAW_FILES),)
	# additional raw files relative to root: $(DEBIAN_RAW_FILES) in: $(DEBIAN_RAW_SUBDIR) for: /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)
	mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)"
ifeq ($(findstring //,/$(DEBIAN_RAW_SUBDIR)),//)
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C $(DEBIAN_RAW_SUBDIR) $(DEBIAN_RAW_FILES) | (cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)" && $(TAR) xvf -)
#	rsync -avz --exclude .DS_Store --exclude .svn $(DEBIAN_RAW_SUBDIR) $(DEBIAN_RAW_FILES) "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)"
else
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C $(PWD)/$(DEBIAN_RAW_SUBDIR) $(DEBIAN_RAW_FILES) | (cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)" && $(TAR) xvf -)
#	rsync -avz --exclude .DS_Store --exclude .svn $(PWD)/$(DEBIAN_RAW_SUBDIR) $(DEBIAN_RAW_FILES) "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)")
endif
endif
	# unprotect
	chmod -Rf u+w "/tmp/$(TMP_DATA)" || true

prune_temp_files:
ifneq ($(TRIPLE),)
	# remove foreign architectures in /tmp/$(TMP_DATA) except $(TRIPLE)
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/MacOS' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/php' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
ifeq ($(WRAPPER_EXTENSION),framework)
	# process multirelease framework
	[ -f "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/$(PRODUCT_NAME)" ] || \
		ln -sf "lib$(PRODUCT_NAME)-$(DEBIAN_RELEASE).so" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/lib$(PRODUCT_NAME).so"
	( cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/" && \
	for NAME in "lib$(PRODUCT_NAME)-"*.so; \
	do [ "$$NAME" != "lib$(PRODUCT_NAME)-$(DEBIAN_RELEASE).so" ] && rm -f "$$NAME"; \
	done; true )
endif
endif
ifeq ($(WRAPPER_EXTENSION),framework)
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)"
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)"
endif

# filter "release:package" and "package [architecture..]"
# rules
#   ignore if it has any release: prefix and none does match $(DEBIAN_RELEASE)
#   ignore if it has [] and non architecture... does match $(DEBIAN_ARCH)

F = filter_dependencies() \
{ \
	tr ',' '\n' | \
	( \
	SEP="$$1"; \
	while read LINE; \
	do \
		if echo "$$LINE" | grep -q : && ! echo "$$LINE" | grep -q "$(DEBIAN_RELEASE):"; then continue; fi; \
		if echo "$$LINE" | grep -q '\[.*\]' && ! echo "$$LINE" | grep -q "\[[^]]*$(DEBIAN_ARCH).*\]"; then continue; fi; \
		LINE=$$(echo "$$LINE" | sed 's|.*:||' | sed 's|[ ]*\[.*\][ ]*||'); \
		if [ "$(TRIPLE)" = "php" ] && ! echo "$$LINE" | egrep -q '^quantumstep-|^letux-'; then continue; fi; \
		if [ "$$LINE" ]; then \
			printf "%s" "$$SEP $$LINE"; SEP=","; \
		fi; \
	done; \
	[ "$$SEP" = "," ] && echo ); \
}

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb":
	# make debian package $(DEBIAN_PACKAGE_NAME)_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb
	# DEBIAN_SECTION: $(DEBIAN_SECTION)
	# DEBIAN_PRIORITY: $(DEBIAN_PRIORITY)
	# DEBIAN_CONTROL: $(DEBIAN_CONTROL)
	# DEBIAN_DEPENDS: $(DEBIAN_DEPENDS)
	# DEBIAN_RECOMMENDS: $(DEBIAN_RECOMMENDS)
	# DEBIAN_CONFLICTS: $(DEBIAN_CONFLICTS)
	# DEBIAN_REPLACES: $(DEBIAN_REPLACES)
	# DEBIAN_PROVIDES: $(DEBIAN_PROVIDES)
	$(QUIET)mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
	$(QUIET)chmod -Rf u+w "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)" 2>/dev/null || true
ifneq ($(TRIPLE),)
	# remove foreign architectures in /tmp/$(TMP_DATA) except $(TRIPLE)
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/MacOS' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/php' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
ifeq ($(WRAPPER_EXTENSION),framework)
	# remove headers
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/Headers" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/Headers" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/Headers.link"
	# process multirelease framework
	[ -f "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/$(PRODUCT_NAME)" ] || \
		ln -sf "lib$(PRODUCT_NAME)-$(DEBIAN_RELEASE).so" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/lib$(PRODUCT_NAME).so"
	( cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/" && \
	for NAME in "lib$(PRODUCT_NAME)-"*.so; \
	do [ "$$NAME" != "lib$(PRODUCT_NAME)-$(DEBIAN_RELEASE).so" ] && rm -f "$$NAME"; \
	done; true )
endif
endif
ifeq ($(WRAPPER_EXTENSION),framework)
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)"
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)"
endif
	# create Receipts file
	$(QUIET)mkdir -p "/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts" && echo $(DEBIAN_PACKAGE_VERSION) >"/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)_@_$(DEBIAN_ARCH).deb"
	# write protect and pack data.tar.gz
	$(QUIET)chmod -Rf a-w "/tmp/$(TMP_DATA)" || true
	$(QUIET)$(TAR) czf /tmp/$(TMP_DATA).tar.gz --owner $(ROOT) --group $(ROOT) -C "/tmp/$(TMP_DATA)" .
	$(QUIET)ls -l "/tmp/$(TMP_DATA).tar.gz"
	# create control.tar.gz
	echo "2.0" >"/tmp/$(TMP_DEBIAN_BINARY)"
	( echo "Package: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Section: $(DEBIAN_SECTION)"; \
	  echo "Priority: $(DEBIAN_PRIORITY)"; \
	  echo "Version: $(DEBIAN_PACKAGE_VERSION)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
	  [ "$(DEBIAN_ARCH)" != all ] && echo "Multi-Arch: same"; \
	  [ "$(DEBIAN_MAINTAINER)" ] && echo "Maintainer: $(DEBIAN_MAINTAINER)"; \
	  [ "$(DEBIAN_HOMEPAGE)" ] && echo "Homepage: $(DEBIAN_HOMEPAGE)"; \
	  [ "$(DEBIAN_SOURCE)" ] && echo "Source: $(DEBIAN_SOURCE)"; \
	  echo "Installed-Size: `du -kHs /tmp/$(TMP_DATA) | cut -f1`"; \
	  $(F); \
	  [ "$(DEBIAN_DEPENDS)" ] && echo "$(DEBIAN_DEPENDS)" | filter_dependencies "Depends:"; \
	  [ "$(DEBIAN_RECOMMENDS)" ] && echo "$(DEBIAN_RECOMMENDS)" | filter_dependencies "Recommends:"; \
	  [ "$(DEBIAN_CONFLICTS)" ] && echo "$(DEBIAN_CONFLICTS)" | filter_dependencies "Conflicts:"; \
	  [ "$(DEBIAN_REPLACES)" ] && echo "$(DEBIAN_REPLACES)" | filter_dependencies "Replaces:"; \
	  [ "$(DEBIAN_PROVIDES)" ] && echo "$(DEBIAN_PROVIDES)" | filter_dependencies "Provides:"; \
	  echo "Description: $(DEBIAN_DESCRIPTION)"; \
	) >"/tmp/$(TMP_CONTROL)/control"
	if [ "$(strip $(DEBIAN_CONTROL))" ]; then for i in $(DEBIAN_CONTROL); do cp $$i /tmp/$(TMP_CONTROL)/$${i##*.}; done; fi
	$(QUIET)$(TAR) czvf /tmp/$(TMP_CONTROL).tar.gz --owner $(ROOT) --group $(ROOT) -C /tmp/$(TMP_CONTROL) .
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	- rm -rf $@
	ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	ls -l $@
ifeq ($(OPEN_DEBIAN),true)
	open $@
endif

# should be the same as without -dev but include headers

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb":
ifeq ($(WRAPPER_EXTENSION),framework)
	# make debian development package $(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb
	# FIXME: make also dependent on location (i.e. public */Frameworks/ only)
	$(QUIET)mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
	$(QUIET)chmod -Rf u+w "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)" 2>/dev/null || true
ifneq ($(TRIPLE),)
	# remove foreign architectures in /tmp/$(TMP_DATA) except $(TRIPLE)
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/MacOS' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/php' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	# process multirelease framework
	[ -f "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/$(PRODUCT_NAME)" ] || \
		ln -sf "lib$(PRODUCT_NAME)-$(DEBIAN_RELEASE).so" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/lib$(PRODUCT_NAME).so"
	( cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/" && \
	for NAME in "lib$(PRODUCT_NAME)-"*.so; \
	do [ "$$NAME" != "lib$(PRODUCT_NAME)-$(DEBIAN_RELEASE).so" ] && rm -f "$$NAME"; \
	done; true )
endif
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)"
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)"
	# strip binaries
	find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	# create Receipts file
	$(QUIET)mkdir -p /tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts && echo $(DEBIAN_PACKAGE_VERSION) >/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dev_@_$(DEBIAN_ARCH).deb
	# write protect and pack data.tar.gz
	$(QUIET)chmod -Rf a-w "/tmp/$(TMP_DATA)" || true
	$(QUIET)$(TAR) czf /tmp/$(TMP_DATA).tar.gz --owner $(ROOT) --group $(ROOT) -C /tmp/$(TMP_DATA) .
	$(QUIET)ls -l /tmp/$(TMP_DATA).tar.gz
	# create control.tar.gz
	echo "2.0" >"/tmp/$(TMP_DEBIAN_BINARY)"
	( echo "Package: $(DEBIAN_PACKAGE_NAME)-dev"; \
	  echo "Section: $(DEBIAN_SECTION)"; \
	  echo "Priority: extra"; \
	  echo "Version: $(DEBIAN_PACKAGE_VERSION)"; \
	  echo "Replaces: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
	  [ "$(DEBIAN_ARCH)" != all ] && echo "Multi-Arch: same"; \
	  [ "$(DEBIAN_MAINTAINER)" ] && echo "Maintainer: $(DEBIAN_MAINTAINER)"; \
	  [ "$(DEBIAN_HOMEPAGE)" ] && echo "Homepage: $(DEBIAN_HOMEPAGE)"; \
	  [ "$(DEBIAN_SOURCE)" ] && echo "Source: $(DEBIAN_SOURCE)"; \
	  echo "Installed-Size: `du -kHs /tmp/$(TMP_DATA) | cut -f1`"; \
	  $(F); \
	  [ "$(DEBIAN_DEPENDS)" ] && echo "$(DEBIAN_DEPENDS)" | filter_dependencies "Depends:"; \
	  [ "$(DEBIAN_RECOMMENDS)" ] && echo "$(DEBIAN_RECOMMENDS)" | filter_dependencies "Recommends:"; \
	  echo "Description: $(DEBIAN_DESCRIPTION)"; \
	) >"/tmp/$(TMP_CONTROL)/control"
	if [ "$(strip $(DEBIAN_CONTROL))" ]; then for i in $(DEBIAN_CONTROL); do cp $$i /tmp/$(TMP_CONTROL)/$${i##*.}; done; fi
	$(QUIET)$(TAR) czvf /tmp/$(TMP_CONTROL).tar.gz $(DEBIAN_CONTROL) --owner $(ROOT) --group $(ROOT) -C /tmp/$(TMP_CONTROL) .
	- rm -rf $@
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	ls -l $@
ifeq ($(OPEN_DEBIAN),true)
	open $@
endif
else
	# no development version
endif

# should be the same as -dev except stripping

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb":
ifeq ($(WRAPPER_EXTENSION),framework)
	# make debian debugging package $(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_PACKAGE_VERSION)_$(DEBIAN_ARCH).deb
	# FIXME: make also dependent on location (i.e. public */Frameworks/ only)
	$(QUIET)mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
ifneq ($(TRIPLE),)
	# remove foreign architectures in /tmp/$(TMP_DATA) except $(TRIPLE)
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/MacOS' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/php' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	# process multirelease framework
	[ -f "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/$(PRODUCT_NAME)" ] || \
		ln -sf "lib$(PRODUCT_NAME)-$(DEBIAN_RELEASE).so" "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/lib$(PRODUCT_NAME).so"
	( cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/" && \
	for NAME in "lib$(PRODUCT_NAME)-"*.so; \
	do [ "$$NAME" != "lib$(PRODUCT_NAME)-$(DEBIAN_RELEASE).so" ] && rm -f "$$NAME"; \
	done; true )
endif
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)"
	rm -rf "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)"
	# create Receipts file
	$(QUIET)chmod -Rf u+w "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)" 2>/dev/null || true
	$(QUIET)mkdir -p /tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts && echo $(DEBIAN_PACKAGE_VERSION) >/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dbg_@_$(DEBIAN_ARCH).deb
	# write protect and pack data.tar.gz
	$(QUIET)chmod -Rf a-w "/tmp/$(TMP_DATA)" || true
	$(QUIET)$(TAR) czf /tmp/$(TMP_DATA).tar.gz --owner $(ROOT) --group $(ROOT) -C /tmp/$(TMP_DATA) .
	$(QUIET)ls -l /tmp/$(TMP_DATA).tar.gz
	# create control.tar.gz
	echo "2.0" >"/tmp/$(TMP_DEBIAN_BINARY)"
	( echo "Package: $(DEBIAN_PACKAGE_NAME)-dbg"; \
	  echo "Section: $(DEBIAN_SECTION)"; \
	  echo "Priority: extra"; \
	  echo "Version: $(DEBIAN_PACKAGE_VERSION)"; \
	  echo "Replaces: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
	  [ "$(DEBIAN_ARCH)" != all ] && echo "Multi-Arch: same"; \
	  [ "$(DEBIAN_MAINTAINER)" ] && echo "Maintainer: $(DEBIAN_MAINTAINER)"; \
	  [ "$(DEBIAN_HOMEPAGE)" ] && echo "Homepage: $(DEBIAN_HOMEPAGE)"; \
	  [ "$(DEBIAN_SOURCE)" ] && echo "Source: $(DEBIAN_SOURCE)"; \
	  echo "Installed-Size: `du -kHs /tmp/$(TMP_DATA) | cut -f1`"; \
	  $(F); \
	  [ "$(DEBIAN_DEPENDS)" ] && echo "$(DEBIAN_DEPENDS)" | filter_dependencies "Depends:"; \
	  [ "$(DEBIAN_RECOMMENDS)" ] && echo "$(DEBIAN_RECOMMENDS)" | filter_dependencies "Recommends:"; \
	  echo "Description: $(DEBIAN_DESCRIPTION)"; \
	) >"/tmp/$(TMP_CONTROL)/control"
	if [ "$(strip $(DEBIAN_CONTROL))" ]; then for i in $(DEBIAN_CONTROL); do cp $$i /tmp/$(TMP_CONTROL)/$${i##*.}; done; fi
	$(QUIET)$(TAR) czf /tmp/$(TMP_CONTROL).tar.gz $(DEBIAN_CONTROL) --owner $(ROOT) --group $(ROOT) -C /tmp/$(TMP_CONTROL) .
	- rm -rf $@
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	$(QUIET)ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	$(QUIET)ls -l $@
ifeq ($(OPEN_DEBIAN),true)
	@open $@
endif
else
	# no debug version
endif

# this runs in outer Makefile, i.e. DEBIAN_ARCH and TRIPLE are not well defined

# NOTE: TRIPLE and DEBIAN_ARCH are undefined here!!!
# NOTE: /tmp_CONTROL etc. is a different $$ than when building debian packages!
# this means we must also install from the submakefile

# strip off all that are not MacOS and copy to $(HOST_INSTALL_PATH)
install_local: prepare_temp_files
	@echo install_local
	# install_local TRIPLE=$(TRIPLE) DEBIAN_ARCH=$(DEBIAN_ARCH)
ifeq ($(INSTALL),true)
	# INSTALL: $(INSTALL)
	# should we better untar the .deb?
	- : ls -l "$(BINARY)" # fails for tools because we are on the outer level and have included an empty DEBIAN_ARCH in $(BINARY) and $(PKG)
	- [ -x "$(PKG)/../$(PRODUCT_NAME)" ] && cp -f "$(PKG)/../$(PRODUCT_NAME)" "$(PKG)/$(NAME_EXT)/$(PRODUCT_NAME)" || echo nothing to copy # copy potential MacOS binary
	# FIXME: use rsync
ifeq ($(NAME_EXT),bin)
	# - if [ -d "$(PKG)" ] ; then $(TAR) cf - --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p '$(HOST_INSTALL_PATH)' && cd '$(HOST_INSTALL_PATH)' && (pwd; chmod -Rf u+w '$(HOST_INSTALL_PATH)/$(NAME_EXT)' 2>/dev/null; $(TAR) xpvf -)); fi
	- if [ -d "$(PKG)" ] ; then rsync -avz --exclude .svn "$(PKG)/$(NAME_EXT)" $(HOST_INSTALL_PATH) && (pwd; chmod -Rf u+w '$(HOST_INSTALL_PATH)/$(NAME_EXT)' 2>/dev/null); fi
else
	# - if [ -d "$(PKG)" ] ; then $(TAR) cf - --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p '$(HOST_INSTALL_PATH)' && cd '$(HOST_INSTALL_PATH)' && (pwd; chmod -Rf u+w '$(HOST_INSTALL_PATH)/$(NAME_EXT)' 2>/dev/null; $(TAR) xpvf - -U --recursive-unlink)); fi
	- if [ -d "$(PKG)" ] ; then rsync -avz --exclude .svn "$(PKG)/$(NAME_EXT)" $(HOST_INSTALL_PATH) && (pwd; chmod -Rf u+w '$(HOST_INSTALL_PATH)/$(NAME_EXT)' 2>/dev/null); fi
endif
	# FIXME: fix multi-release symlinks for frameworks on device like in deploy_remote
	# installed on localhost at $(HOST_INSTALL_PATH)
else
	# don't install locally
endif
	@echo install_local done

# can we have a mode where we don't run but deploy to the runnable device only?
# maybe RUN=true DEPLOY=true RUN_CMD=:
ifeq ($(RUN),true)
# to run device only
DEVICELIST:=-r
# this one could strip off architectures different from the one to download
else
# to all devices
# FIXME: to all reachable devices?
DEVICELIST:=-n
endif
# TRIPLE is undefined here!
deploy_remote: prepare_temp_files
	@echo deploy_remote
ifeq ($(DEPLOY),true)
	# DEPLOY: $(DEPLOY)
	# deploy remote
	# DOWNLOAD /tmp/$(TMP_DATA) to all devices
	# FIXME: use rsync?
	- [ -s "$(DOWNLOAD_TOOL)" ] && $(DOWNLOAD_TOOL) $(DEVICELIST) | while read DEVICE NAME; \
		do \
		$(TAR) cf - --exclude .svn --owner 500 --group 1 -C "/tmp/$(TMP_DATA)" . | \
				gzip | \
				$(DOWNLOAD_TOOL) $$DEVICE "cd; cd / && gunzip | tar xpvf -; if cd $(TARGET_INSTALL_PATH)/$(PRODUCT_NAME).$(WRAPPER_EXTENSION)/$(CONTENTS)/\$$HOSTTYPE-\$$OSTYPE 2>/dev/null && [ \"$(WRAPPER_EXTENSION)\" = framework -a ! -f $(PRODUCT_NAME) ]; then ln -sf lib$(PRODUCT_NAME)-\$$(lsb_release -c | cut -f 2).so lib$(PRODUCT_NAME).so; ls -l lib$(PRODUCT_NAME)*.so; fi;" \
				&& echo +++ installed on $$NAME at $(TARGET_INSTALL_PATH) +++ || echo --- installation failed on $$NAME ---; \
		done
	#done
else
	# not deployed
endif
	@echo deploy_remote done

launch_remote:
ifeq ($(DEPLOY),true)
ifeq ($(RUN),true)
ifeq ($(WRAPPER_EXTENSION),app)
	@echo launch_remote
	# DEPLOY: $(DEPLOY)
	# RUN: $(RUN)
	# RUN_CMD: $(RUN_CMD)
	#
	# try to launch deployed Application using local Xquartz as a remote display
	@-rm -rf /tmp/.X0-lock /tmp/.X11-unix 2>/dev/null | true
	@-[ "$$(pgrep Xquartz)" ] || ( defaults write org.macosforge.xquartz.X11 nolisten_tcp 0 && open -a Xquartz && sleep 5 && export DISPLAY=localhost:0.0 && $(XHOST_TOOL) + ) || true
	"$(DOWNLOAD_TOOL)" "$(shell $(DOWNLOAD_TOOL) -r)" "cd; : set; : export QuantumSTEP=$(EMBEDDED_ROOT); : export PATH=\$$PATH:$(EMBEDDED_ROOT)/usr/bin; : export LOGNAME=$(LOGNAME); : export NSLog=yes; : export HOST=\$$(expr \"\$$SSH_CONNECTION\" : '\\(.*\\) .* .* .*'); : export DISPLAY=\$$HOST:0.0; : set; qsx $(RUN_CMD) $(PRODUCT_NAME)" || echo failed to run
# old...	"cd; set; export QuantumSTEP=$(EMBEDDED_ROOT); export PATH=\$$PATH:$(EMBEDDED_ROOT)/usr/bin; export LOGNAME=$(LOGNAME); export NSLog=yes; export HOST=\$$(expr \"\$$SSH_CONNECTION\" : '\\(.*\\) .* .* .*'); export DISPLAY=\$$HOST:0.0; set; export EXECUTABLE_PATH=Contents/$(TRIPLE); cd '$(TARGET_INSTALL_PATH)' && $(RUN_CMD) '$(PRODUCT_NAME)' $(RUN_OPTIONS)"
	@echo launch_remote done
endif
endif
endif

# generic bundle rule

# FIXME: use dependencies to link only if any object file has changed

# replace this by make_binary and make_bundle

# link headers of framework

bundle:
	@echo bundle
ifneq ($(TRIPLE),unknown-linux-gnu)
	# create bundle $(PKG)/$(NAME_EXT)
ifeq ($(WRAPPER_EXTENSION),framework)
	@[ ! -L "$(PKG)/$(NAME_EXT)/$(CONTENTS)" -a -d "$(PKG)/$(NAME_EXT)/$(CONTENTS)" ] && rm -rf "$(PKG)/$(NAME_EXT)/$(CONTENTS)" || echo nothing to remove # remove directory
	@rm -f "$(PKG)/$(NAME_EXT)/$(CONTENTS)" # remove symlink
	@(mkdir -p "$(PKG)/$(NAME_EXT)/Versions/$(FRAMEWORK_VERSION)" && ln -sf $(FRAMEWORK_VERSION) "$(PKG)/$(NAME_EXT)/$(CONTENTS)")	# link Current to -> $(FRAMEWORK_VERSION)
	@rm -f "$(PKG)/$(NAME_EXT)/Versions/Current/$(EXECUTABLE_NAME)"; ln -sf "MacOS/lib$(EXECUTABLE_NAME).dylib" "$(PKG)/$(NAME_EXT)/Versions/Current/$(EXECUTABLE_NAME)"
	@rm -f "$(PKG)/$(NAME_EXT)/$(PRODUCT_NAME)"; ln -sf "Versions/Current/$(EXECUTABLE_NAME)" "$(PKG)/$(NAME_EXT)/$(PRODUCT_NAME)"
	@rm -f "$(PKG)/$(NAME_EXT)/Headers"; ln -sf "Versions/Current/Headers" "$(PKG)/$(NAME_EXT)/Headers"
	@rm -f "$(PKG)/$(NAME_EXT)/Modules"; ln -sf "Versions/Current/Modules" "$(PKG)/$(NAME_EXT)/Modules"
	@rm -f "$(PKG)/$(NAME_EXT)/Resources"; ln -sf "Versions/Current/Resources" "$(PKG)/$(NAME_EXT)/Resources"
endif
endif
	@echo bundle done

headers:
	@echo headers
ifneq ($(TRIPLE),unknown-linux-gnu)
	# create headers $(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers
ifeq ($(WRAPPER_EXTENSION),framework)
ifneq ($(strip $(HEADERSRC)),)
# included header files $(HEADERSRC)
#	$(TAR) -cf /dev/null --transform='s|Source/||;s|Sources/||;s|src/||' --verbose --show-transformed-names $(HEADERSRC)
	$(QUIET)- (mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" && $(TAR) -cf - --transform='s|Source/||;s|Sources/||;s|src/||' $(HEADERSRC) | (cd "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" && $(TAR) xf -) )	# copy headers keeping subdirectory structure
endif
#ifeq ($(DEBIAN_RELEASE),none)
#	$(QUIET)- (mkdir -p "$(EXEC)/Headers" && rm -f $(HEADERS) && ln -sf ../../Headers "$(HEADERS)")	# link to Headers to find <Framework/File.h>
#else
#	$(QUIET)- (mkdir -p "$(EXEC)/Headers" && rm -f $(HEADERS) && ln -sf ../../../../Headers "$(HEADERS)")	# link to Headers to find <Framework/File.h>
#endif
	$(QUIET)- (mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers.link"; rm -f "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers.link/$(PRODUCT_NAME)" && ln -sf ../Headers "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers.link/$(PRODUCT_NAME)")	# link to Headers to find <Framework/File.h>
endif
ifeq ($(TRIPLE),MacOS)
# always use system frameworks and make nested frameworks "flat"
	$(QUIET)mkdir -p $(TTT)
	$(QUIET)- for fwk in $(shell find /System/Library/Frameworks -name '*.framework' | sed "s/\.framework//g" ); \
	  do \
	      rm -f $(TTT)/$$(basename $$fwk); \
		  ln -sf $$fwk/Versions/Current/Headers $(TTT)/$$(basename $$fwk) \
	  ; done
endif
endif
	@echo headers done

resources: bundle
	@echo resources
ifneq ($(TRIPLE),unknown-linux-gnu)
	chmod -Rf u+w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" 2>/dev/null || true # unprotect resources
# copy resources to $(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources
ifneq ($(WRAPPER_EXTENSION),)
# included resources $(INFOPLISTS) $(RESOURCES)
	$(QUIET)- mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)"
ifneq ($(strip $(INFOPLISTS)),)
# should reject multiple Info.plists
# should expand ${EXECUTABLE_NAME} and other macros!
	$(QUIET)- sed 's/$${EXECUTABLE_NAME}/$(EXECUTABLE_NAME)/g; s/$${MACOSX_DEPLOYMENT_TARGET}/10.0/g; s/$${PRODUCT_NAME:rfc1034identifier}/$(PRODUCT_NAME)/g; s/$${PRODUCT_NAME:identifier}/$(PRODUCT_NAME)/g; s/$${PRODUCT_NAME}/$(PRODUCT_NAME)/g; s/$$(PRODUCT_BUNDLE_IDENTIFIER)/$(PRODUCT_BUNDLE_IDENTIFIER)/g' <"$(INFOPLISTS)" >"$(PKG)/$(NAME_EXT)/$(CONTENTS)/Info.plist"
else
# create a default Info.plist
	echo "Error: missing Info.plist - creating a default"
	- (echo "CFBundleName = $(PRODUCT_NAME);"; echo "CFBundleExecutable = $(EXECUTABLE_NAME);") >"$(PKG)/$(NAME_EXT)/$(CONTENTS)/Info.plist"
endif
ifneq ($(strip $(RESOURCES)),)
	$(QUIET)- mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources"
#	- cp $(RESOURCES) "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/"  # copy resources
	for resource in $(RESOURCES); \
	do \
	(cd $$(dirname "$$resource") && $(TAR) cf - -h --exclude .DS_Store --exclude .git --exclude .svn $$(basename "$$resource")) | (cd "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" && $(TAR) xvf - ); \
	done
# convert any xib to nib
	find "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" -name '*.xib' -print -exec sh -c 'ibtool --compile "$$(dirname {})/$$(basename {} .xib).nib" "{}"' ';' -delete
endif
endif
	chmod -R a-w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/"* 2>/dev/null || true	# write protect resources
endif
	@echo resources done

"$(BINARY)":: bundle headers $(OBJECTS) $(PHPOBJECTS)
ifeq ($(TRIPLE),php)
ifneq ($(strip $(PHPSRCS)),)
	# PHPSRCS: $(PHPSRCS)
	# PHPOBJECTS: $(PHPOBJECTS)

	# can be removed later
	for PHP in $(PHPSRCS); \
	do \
		if [ -r "$$PHP" ]; \
		then \
			mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php" && \
			php -l "$$PHP" && \
			chmod -Rf u+w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/"; \
			cp -pf "$$PHP" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/" && \
			: cp -pf "$$PHP" "$(BINARY)" && \
			chmod -R a-w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/"; \
		fi; \
		done
	# we need to fake a binary for the Makefile rule
	#chmod -Rf u+w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/"; \
	#echo "<?php ?>" >"$(BINARY)"; \
	#chmod -R a-w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/";
	chmod -Rf u+w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/"
	# assume we have compiled PHPSRCS -> PHPOBJECTS by rule
	@mkdir -p "$(EXEC)"
	rm -f "$(BINARY)"
	php -d phar.readonly=0 -r '$$pharFile=$$argv[1]; \
	if(file_exists($$pharFile)) unlink($$pharFile); \
	$$phar=new Phar($$pharFile); \
	$$phar->startBuffering(); \
	$$defaultStub=$$phar->createDefaultStub("$(PRODUCT_NAME).php", "$(PRODUCT_NAME).php"); \
	for($$i=2;$$i<$$argc;$$i++) $$phar->addfile($$argv[$$i], ltrim(basename($$argv[$$i], ".o").".php", "+")); \
	$$stub="#!/usr/bin/env php \n".$$defaultStub; \
	$$phar->setStub($$stub); \
	$$phar->stopBuffering(); \
	$$phar->compressFiles(Phar::GZ); \
	' "$(BINARY).phar" $(PHPOBJECTS) && chmod 0555 "$(BINARY).phar" && mv "$(BINARY).phar" "$(BINARY)"
	phar list -f "$(BINARY)"

endif
endif
ifneq ($(OBJECTS),)
	# link for $(ARCH): $(SRCOBJECTS) -> $(OBJECTS) -> $(BINARY)
	@mkdir -p "$(EXEC)"
	$(LD) $(LDFLAGS) -o "$(BINARY)" $(OBJECTS) $(LIBRARIES)
	$(NM) -u "$(BINARY)"
	# linked.
ifeq ($(WRAPPER_EXTENSION),)
	- rm -f "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(EXECUTABLE_NAME)"
	# link is no longer needed since we assume /usr/bin/$(TRIPLE) to come in the $PATH before /usr/bin
	# - ln -sf "$(TRIPLE)/$(EXECUTABLE_NAME)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(EXECUTABLE_NAME)"	# create link to current architecture
else ifeq ($(WRAPPER_EXTENSION),framework)
	# link shared library for frameworks
	- rm -f "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/$(EXECUTABLE_NAME)"
ifeq ($(TRIPLE),MacOS)
	- ln -sf "$(TRIPLE)/lib$(EXECUTABLE_NAME).$(SO)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(EXECUTABLE_NAME)"	# create link to MacOS version
else
	- ln -sf "lib$(EXECUTABLE_NAME).$(SO)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/$(EXECUTABLE_NAME)"	# create libXXX.so entry for ldconfig
endif
endif
endif

"$(EXEC)":: bundle headers resources
	@echo $(EXEC)
ifneq ($(TRIPLE),unknown-linux-gnu)
	# make directory for executable
	# INCLUDES: $(INCLUDES)
	# SOURCES: $(SOURCES)
	# SRCOBJECTS: $(SRCOBJECTS)
	# OBJCSRCS: $(OBJCSRCS)
	# FRAMEWORKS: $(FRAMEWORKS)
	# CSRCS: $(CSRCS)
	# LEXSRCS: $(LEXSRCS)
	# YACCSRCS: $(YACCSRCS)
	# PHPSRCS: $(PHPSRCS)
	# OBJECTS: $(OBJECTS)
	# PHPOBJECTS: $(PHPOBJECTS)
	# LIBS: $(LIBS)
	# BINARY: $(BINARY)
	# RESOURCES: $(RESOURCES)
	# HEADERS: $(HEADERSRC)
	# INFOPLISTS: $(INFOPLISTS)
	mkdir -p "$(EXEC)"
endif
	@echo resources done

# EOF
