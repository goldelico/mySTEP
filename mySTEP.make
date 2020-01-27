#!/usr/bin/make -f
#
# FIXME: the current directory must be the one that contains the .qcodeproj
#
ifeq (nil,null)   ## this is to allow for the following text without special comment character considerations
#
# This file is part of mySTEP
#
# You should not edit this file as it affects all projects you will compile!
#
# Copyright, H. Nikolaus Schaller <hns@computer.org>, 2003-2018
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
#   (+) RECURSIVE - build subprojects first - default: no
#   (+) BUILD_FOR_DEPLOYMENT - default: no
#   (+) OPTIMIZE - optimize level - default: s
#   (+) INSPECT - save .i and .S intermediate steps - default: no
#   (+) BUILD_STYLE - default: ?
#   (+) GCC_OPTIMIZATION_LEVEL - default: 0
#   (+) BUILD_DOCUMENTATION - default: no
#   (*) DEBIAN_ARCHITECTURES - default:
#   (-) DEBIAN_ARCH - used internally
#   (+) DEBIAN_RELEASE - the release to build for (modifies compiler, libs and staging for result)- default: staging
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
#   * DEBIAN_PACKAGE_NAME - quantumstep-$PRODUCT_NAME-$WRAPPER-extension
#   - DEBIAN_VERSION - current date/time
#   (+) DEBDIST - where to store the binary-arch files - default: $QuantumSTEP/System/Installation/Debian/dists
#   (*) DEBIAN_DEPENDS - quantumstep-cocoa-framework
#   (*) DEBIAN_RECOMMENDS - quantumstep-cocoa-framework
#   (*) DEBIAN_CONFLICTS -
#   (*) DEBIAN_REPLACES -
#   (*) DEBIAN_PROVIDES -
#   (*) DEBIAN_HOMEPAGE - www.quantum-step.com
#   (*) DEBIAN_DESCRIPTION
#   (*) DEBIAN_MAINTAINER
#   (*) DEBIAN_SECTION - x11
#   (*) DEBIAN_PRIORITY - optional
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
#   (+) DEPLOY - default: no
#   (+) RUN - default: no
#   (+) RUN_CMD
#
# targets
#   build:		build everything (outer level)
#   build_deb:		called recursively to build for a specific debian architecture
#   clean:		clears build directory (not for subprojects)
#   debug:		print all variable

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

ifeq ($(PRODUCT_BUNDLE_IDENTIFIER),)
PRODUCT_BUNDLE_IDENTIFIER=org.quantumstep.$(PRODUCT_NAME)
endif

ifeq ($(TRIPLE),php)
CC := : php -l
LD := : cp
AS := :
NM := :
STRIP := :
SO :=
else ifeq ($(TRIPLE),darwin-x86_64)
DEFINES += -D__mySTEP__
INCLUDES += -I/opt/local/include -I/opt/local/include/X11 -I/opt/local/include/freetype2 -I/opt/local/lib/libffi-3.2.1/include
TOOLCHAIN=/usr/bin
CC := MACOSX_DEPLOYMENT_TARGET=10.5 $(TOOLCHAIN)/gcc
LD := $(CC)
AS := $(TOOLCHAIN)/as
NM := $(TOOLCHAIN)/nm
STRIP := $(TOOLCHAIN)/strip
SO := dylib
else ifeq ($(TRIPLE),MacOS)
TOOLCHAIN=/usr/bin
CC := MACOSX_DEPLOYMENT_TARGET=10.5 $(TOOLCHAIN)/gcc
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
ifeq ($(DEBIAN_RELEASE),staging)
# use default toolchain
TOOLCHAIN := $(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/Current/gcc/$(TRIPLE)
else
# use specific toolchain depending on DEBAIN_RELEASE (wheezy, jessie, stretch)
TOOLCHAIN := $(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions-$(DEBIAN_RELEASE)/Current/gcc/$(TRIPLE)
endif
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

# define CONTENTS subdirectory as expected by the Foundation library

ifeq ($(EXECUTABLE_NAME),All)
EXECUTABLE_NAME=$(PRODUCT_NAME)
endif
ifeq ($(EXECUTABLE_NAME),)
EXECUTABLE_NAME=$(PRODUCT_NAME)
endif

STDCFLAGS := $(CFLAGS)

ifeq ($(WRAPPER_EXTENSION),)	# command line tool
	CONTENTS=.
	# shared between all binary tools
	NAME_EXT=bin
	# this keeps the binaries separated for installation/packaging
	PKG=$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).bin
	EXEC=$(PKG)/$(NAME_EXT)/$(TRIPLE)
	BINARY=$(EXEC)/$(PRODUCT_NAME)
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
	BINARY=$(EXEC)/lib$(EXECUTABLE_NAME).$(SO)
	HEADERS=$(EXEC)/Headers/$(PRODUCT_NAME)
	STDCFLAGS := -I$(EXEC)/Headers/ $(STDCFLAGS)
ifeq ($(TRIPLE),darwin-x86_64)
	LDFLAGS := -dynamiclib -install_name @rpath/$(NAME_EXT)/Versions/Current/$(PRODUCT_NAME) -undefined dynamic_lookup $(LDFLAGS) -compatibility_version $(CURRENT_PROJECT_VERSION)
else ifeq ($(TRIPLE),MacOS)
	LDFLAGS := -dynamiclib -install_name $(HOST_INSTALL_PATH)/$(NAME_EXT)/Versions/Current/$(PRODUCT_NAME) -undefined dynamic_lookup $(LDFLAGS)
else
	LDFLAGS := -shared -Wl,-soname,$(PRODUCT_NAME) $(LDFLAGS)
endif
else
	CONTENTS=Contents
	NAME_EXT=$(PRODUCT_NAME).$(WRAPPER_EXTENSION)
	PKG=$(BUILT_PRODUCTS_DIR)
	EXEC=$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)
	BINARY=$(EXEC)/$(EXECUTABLE_NAME)
ifeq ($(WRAPPER_EXTENSION),app)
#	STDCFLAGS := -DFAKE_MAIN $(STDCFLAGS)	# application
else
ifeq ($(TRIPLE),darwin-x86_64)
	LDFLAGS := -dynamiclib -install_name @rpath/$(NAME_EXT)/Versions/Current/MacOS/$(PRODUCT_NAME) -undefined dynamic_lookup $(LDFLAGS)
else ifeq ($(TRIPLE),MacOS)
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

OBJECTS := $(SRCOBJECTS:%.m=$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.o)
OBJECTS := $(OBJECTS:%.mm=$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.o)
OBJECTS := $(OBJECTS:%.c=$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.o)
OBJECTS := $(OBJECTS:%.cpp=$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.o)
OBJECTS := $(OBJECTS:%.c++=$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.o)

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
DEBIAN_CONTROL := $(filter %.preinst %.postinst %.prerm %.postrm %.conffiles,$(XSOURCES))

# all sources that are processed specially
PROCESSEDSRC := $(SRCOBJECTS) $(PHPSRCS) $(SHSRCS) $(INFOPLISTS) $(HEADERSRC) $(SUBPROJECTS)

# all remaining selected (re)sources
RESOURCES := $(filter-out $(PROCESSEDSRC),$(XSOURCES))

# default is to build for all

ifeq ($(DEBIAN_ARCHITECTURES),)
DEBIAN_ARCHITECTURES=darwin-x86_64 armel armhf arm64 i386 mipsel php
# mystep (= use our frameworks and X11 except Foundation) does not work yet
# DEBIAN_ARCHITECTURES+=mystep darwin-x86_64
ifeq ($(PHPONLY),true)
DEBIAN_ARCHITECTURES=php
endif
# DEBIAN_ARCHITECTURES=macos
endif

# this is the default/main target on the outer level

ifeq ($(NOCOMPILE),true)
build:	build_subprojects build_doxy install_local
else
build:	build_subprojects build_doxy build_architectures make_sh install_local deploy_remote launch_remote
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
ifneq ($(DEBIAN_ARCHITECTURES),none)
ifneq ($(DEBIAN_ARCHITECTURES),)
# recursively make for all architectures $(DEBIAN_ARCHITECTURES) and RELEASES as defined in DEBIAN_DEPENDS
	RELEASES=$$(echo "$(DEBIAN_DEPENDS)" "$(DEBIAN_RECOMMENDS) $(DEBIAN_CONFLICTS) $(DEBIAN_REPLACES) $(DEBIAN_PROVIDES)" | tr ',' '\n' | fgrep ':' | sed 's/ *\(.*\):.*/\1/g' | sort -u); \
	[ "$$RELEASES" ] || RELEASES="staging"; \
	echo $$RELEASES; \
	for DEBIAN_RELEASE in $$RELEASES; do \
		for DEBIAN_ARCH in $(DEBIAN_ARCHITECTURES); do \
			EXIT=1; \
			case "$$DEBIAN_ARCH" in \
			armel ) export TRIPLE=arm-linux-gnueabi;; \
			armhf ) export TRIPLE=arm-linux-gnueabihf;; \
			arm64 ) export TRIPLE=aarch64-linux-gnu;; \
			i386 ) export TRIPLE=i486-linux-gnu;; \
			mipsel ) export TRIPLE=mipsel-linux-gnu;; \
			darwin-x86_64 ) export TRIPLE=MacOS; EXIT=0;; \
			mystep ) export TRIPLE=darwin-x86_64; EXIT=0;; \
			all ) export TRIPLE=all;; \
			php ) export TRIPLE=php;; \
			*-*-* ) export TRIPLE="$$DEBIAN_ARCH";; \
			* ) export TRIPLE=unknown-linux-gnu;; \
		esac; \
		echo "*** building for $$DEBIAN_RELEASE / $$DEBIAN_ARCH using $$TRIPLE ***"; \
		export DEBIAN_RELEASE="$$DEBIAN_RELEASE"; \
		export DEBIAN_ARCH="$$DEBIAN_ARCH"; \
		export TRIPLE="$$TRIPLE"; \
		make -f $(QuantumSTEP)/System/Sources/Frameworks/mySTEP.make build_deb; \
		echo "$$DEBIAN_ARCH" done; \
		done \
	done
endif
endif

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
FRAMEWORKS := Foundation AppKit $(FRAMEWORKS)
endif

### FIXME: we should only -I the $(FRAMEWORKS) requested and not all existing!
### But we don't know exactly where it is located
INCLUDES += \
-I$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(TRIPLE)/usr/include/freetype2 \
-I$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE)/Headers | sed "s/ / -I/g"') \
-I$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE)/Headers | sed "s/ / -I/g"') \
-I$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE)/Headers | sed "s/ / -I/g"')

# allow to use #import <framework/header.h> while building the framework
INCLUDES := -I$(TARGET_BUILD_DIR)/$(TRIPLE)/ -I$(PKG)/$(NAME_EXT)/Versions/Current/$(TRIPLE)/Headers $(INCLUDES)

ifneq ($(strip $(OBJCSRCS)),)	# any objective C source
ifeq ($(TRIPLE),darwin-x86_64)
FMWKS := $(addprefix -framework ,$(FRAMEWORKS))
# should be similar to MacOS but only link against MacOS CoreFoundation and Foundation
else ifeq ($(TRIPLE),MacOS)
# check if each framework exists in /System/Library/*Frameworks or explicitly include/link from $(QuantumSTEP)
INCLUDES += $(shell for FMWK in CoreFoundation $(FRAMEWORKS); \
	do \
	if [ -d /System/Library/Frameworks/$${FMWK}.framework ]; \
	then :; \
	elif [ -d $(QuantumSTEP)/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/Library/Frameworks/$$FMWK.framework/Versions/Current/$(TRIPLE)/Headers; \
	elif [ -d $(QuantumSTEP)/System/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/System/Library/Frameworks/$$FMWK.framework/Versions/Current/$(TRIPLE)/Headers; \
	elif [ -d $(QuantumSTEP)/System/Library/PrivateFrameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/System/Library/PrivateFrameworks/$$FMWK.framework/Versions/Current/$(TRIPLE)/Headers; \
	elif [ -d $(QuantumSTEP)/Developer/Library/Frameworks/$$FMWK.framework ]; \
	then echo -I$(QuantumSTEP)/Developer/Library/Frameworks/$$FMWK.framework/Versions/Current/$(TRIPLE)/Headers; \
	else echo -I$$FMWK.headers; \
	fi; done)
LIBS += $(shell for FMWK in CoreFoundation $(FRAMEWORKS); \
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
FMWKS := $(addprefix -l ,$(FRAMEWORKS))
endif
endif

#		-L$(TOOLCHAIN)/lib \

# FIXME: use $(addprefix -L,$(wildcard $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE))
# and $(addprefix "-Wl,-rpath-link,",$(wildcard $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE))

#		$(addprefix -L,$(wildcard $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE))) \

ifeq ($(TRIPLE),darwin-x86_64)
LIBRARIES := -L/opt/local/lib \
		/System/Library/Frameworks/Foundation.framework/Versions/Current/Foundation \
		/System/Library/Frameworks/CoreFoundation.framework/Versions/Current/CoreFoundation \
		/System/Library/Frameworks/Security.framework/Versions/Current/Security \
		/System/Library/Frameworks/AppKit.framework/Versions/Current/AppKit \
		/System/Library/Frameworks/Cocoa.framework/Versions/Current/Cocoa \
		-L$(QuantumSTEP)/usr/lib \
		-L$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(TRIPLE)/usr/lib \
		-L$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -L/g"') \
		-L$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -L/g"') \
		-L$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -L/g"') \
		-Wl,-rpath,$(QuantumSTEP)/usr/lib \
		-Wl,-rpath,$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(TRIPLE)/usr/lib \
		-Wl,-rpath,$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -Wl,-rpath,/g"') \
		-Wl,-rpath,$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -Wl,-rpath,/g"') \
		-Wl,-rpath,$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -Wl,-rpath,/g"') \
		$(FMWKS) \
		$(LIBS)
else ifeq ($(TRIPLE),MacOS)
LIBRARIES := \
		$(FMWKS) \
		$(LIBS)
else ifeq ($(TRIPLE),php)
# nothing
else
LIBRARIES := \
		-Wl,-rpath-link,$(QuantumSTEP)/usr/lib \
		-Wl,-rpath-link,$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(TRIPLE)/usr/lib \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -Wl,-rpath-link,/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -Wl,-rpath-link,/g"') \
		-Wl,-rpath-link,$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -Wl,-rpath-link,/g"') \
		-L$(QuantumSTEP)/usr/lib \
		-L$(QuantumSTEP)/System/Library/Frameworks/System.framework/Versions/$(TRIPLE)/usr/lib \
		-L$(shell sh -c 'echo $(QuantumSTEP)/System/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -L/g"') \
		-L$(shell sh -c 'echo $(QuantumSTEP)/Developer/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -L/g"') \
		-L$(shell sh -c 'echo $(QuantumSTEP)/Library/*Frameworks/*.framework/Versions/Current/$(TRIPLE) | sed "s/ / -L/g"') \
		$(FMWKS) \
		$(LIBS)

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

ifeq ($(TRIPLE),darwin-x86_64)
STDCFLAGS += -Wno-deprecated-declarations
else ifeq ($(TRIPLE),MacOS)
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

$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.o: %.m
	@- mkdir -p $(TARGET_BUILD_DIR)/$(TRIPLE)/+$(*D)
	# compile $< -> $*.o
	if ! $(CC) -v 2>/dev/null; then echo "can't find $(CC)"; false; fi
ifeq ($(INSPECT),true)
	$(CC) -c $(OBJCFLAGS) -E $< -o $(TARGET_BUILD_DIR)/$(TRIPLE)/+$*.i	# store preprocessor result for debugging
	$(CC) -c $(OBJCFLAGS) -S $< -o $(TARGET_BUILD_DIR)/$(TRIPLE)/+$*.S	# store assembler source for debugging
endif
	$(CC) -c $(OBJCFLAGS) $< -o $(TARGET_BUILD_DIR)/$(TRIPLE)/+$*.o

$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.o: %.c
	@- mkdir -p $(TARGET_BUILD_DIR)/$(TRIPLE)/+$(*D)
	# compile $< -> $*.o
	if ! $(CC) -v 2>/dev/null; then echo "can't find $(CC)"; false; fi
	$(CC) -c $(STDCFLAGS) $< -o $(TARGET_BUILD_DIR)/$(TRIPLE)/+$*.o

$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.o: %.cpp
	@- mkdir -p $(TARGET_BUILD_DIR)/$(TRIPLE)/+$(*D)
	# compile $< -> $*.o
	if ! $(CC) -v 2>/dev/null; then echo "can't find $(CC)"; false; fi
	$(CC) -c $(STDCFLAGS) $< -o $(TARGET_BUILD_DIR)/$(TRIPLE)/+$*.o

$(TARGET_BUILD_DIR)/$(TRIPLE)/+%.php: %.php
	@- mkdir -p $(TARGET_BUILD_DIR)/$(TRIPLE)/+$(*D)
	# compile $< -> $*.o
	# if ! $(CC) -v 2>/dev/null; then echo "can't find $(CC)"; false; fi
	# php -l $< >$(TARGET_BUILD_DIR)/$(TRIPLE)/+$*.o

# FIXME: handle .lm .ym

#
# makefile targets
#

# FIXME: we can't easily specify the build order (e.g. Foundation first, then AppKit and finally Cocoa)

build_subprojects:
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

make_exec: "$(EXEC)"
	# make exec

make_binary: make_exec "$(BINARY)"
	- [ -x "$(BINARY)" ] && ls -l "$(BINARY)"

make_sh: bundle
	# SHSRCS: $(SHSRCS)
	for SH in $(SHSRCS); do \
		mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" && \
		chmod -Rf u+w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" && \
		cp -pf "$$SH" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" && \
		chmod -R a-w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/"; \
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
ifeq ($(DEBIAN_VERSION),)
DEBIAN_VERSION := 0.$(shell date '+%Y%m%d%H%M%S' )
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
	echo build_deb done

ifeq ($(DEBIAN_NOPACKAGE),)
ifneq ($(TRIPLE),php)
build_debian_packages: prepare_temp_files \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb" \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb"
else
build_debian_packages: prepare_temp_files \
	"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb"
endif
	# debian_packages
	# DEBIAN_ARCH=$(DEBIAN_ARCH)
	# TRIPLE=$(TRIPLE)
	@echo build_debian_packages done
else
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
	if [ -d "$(PKG)" ] ; then $(TAR) cf - --exclude .DS_Store --exclude .svn --exclude Headers -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf -) ; fi
ifneq ($(FILES),)
	# additional files relative to install location
	echo FILES is obsolete
	exit 1
	$(TAR) cf - --exclude .DS_Store --exclude .svn --exclude Headers -C "$(PWD)" $(FILES) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf -)
endif
ifneq ($(DATA),)
	# additional files relative to root $(DATA)
	echo DATA is obsolete
	exit 1
	$(TAR) cf - --exclude .DS_Store --exclude .svn --exclude Headers -C "$(PWD)" $(DATA) | (cd "/tmp/$(TMP_DATA)/" && $(TAR) xvf -)
endif
ifneq ($(DEBIAN_RAW_FILES),)
	# additional raw files relative to root: $(DEBIAN_RAW_FILES) in: $(DEBIAN_RAW_SUBDIR) for: /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)
	mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)"
ifeq ($(findstring //,/$(DEBIAN_RAW_SUBDIR)),//)
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C $(DEBIAN_RAW_SUBDIR) $(DEBIAN_RAW_FILES) | (cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)" && $(TAR) xvf -)
else
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C $(PWD)/$(DEBIAN_RAW_SUBDIR) $(DEBIAN_RAW_FILES) | (cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(DEBIAN_RAW_PREFIX)" && $(TAR) xvf -)
endif
endif
	# unprotect
	chmod -Rf u+w "/tmp/$(TMP_DATA)" || true
ifneq ($(TRIPLE),)
	# remove foreign architectures in /tmp/$(TMP_DATA) except $(TRIPLE)
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/MacOS' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" "(" -path '*/php' ! -name "$(TRIPLE)" ")" -prune -print -exec rm -rf {} ";"
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

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb":
	# make debian package $(DEBIAN_PACKAGE_NAME)_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb
	# DEBIAN_SECTION: $(DEBIAN_SECTION)
	# DEBIAN_PRIORITY: $(DEBIAN_PRIORITY)
	# DEBIAN_CONTROL: $(DEBIAN_CONTROL)
	# DEBIAN_DEPENDS: $(DEBIAN_DEPENDS)
	# DEBIAN_RECOMMENDS: $(DEBIAN_RECOMMENDS)
	# DEBIAN_CONFLICTS: $(DEBIAN_CONFLICTS)
	# DEBIAN_REPLACES: $(DEBIAN_REPLACES)
	# DEBIAN_PROVIDES: $(DEBIAN_PROVIDES)
	mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
	# strip binaries
	find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	# create Receipts file
	mkdir -p "/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts" && echo $(DEBIAN_VERSION) >"/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)_@_$(DEBIAN_ARCH).deb"
	# write protect and pack data.tar.gz
	chmod -Rf a-w "/tmp/$(TMP_DATA)" || true
	$(TAR) cf - --owner 0 --group 0 -C "/tmp/$(TMP_DATA)" . | gzip >/tmp/$(TMP_DATA).tar.gz
	ls -l "/tmp/$(TMP_DATA).tar.gz"
	# create control.tar.gz
	echo "2.0" >"/tmp/$(TMP_DEBIAN_BINARY)"
	( echo "Package: $(DEBIAN_PACKAGE_NAME)"; \
	  echo "Section: $(DEBIAN_SECTION)"; \
	  echo "Priority: $(DEBIAN_PRIORITY)"; \
	  echo "Version: $(DEBIAN_VERSION)"; \
	  echo "Architecture: $(DEBIAN_ARCH)"; \
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
	$(TAR) cvf - --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) . | gzip >/tmp/$(TMP_CONTROL).tar.gz
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	- rm -rf $@
	ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	ls -l $@
ifeq ($(OPEN_DEBIAN),true)
	open $@
endif

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb":
	# make debian development package $(DEBIAN_PACKAGE_NAME)-dev_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb
	# FIXME: make also dependent on location (i.e. public */Frameworks/ only)
ifeq ($(WRAPPER_EXTENSION),framework)
	mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
	# copy again including Headers
	chmod -Rf u+w "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)" || true
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf - && wait && echo done)
	# remove foreign architectures in /tmp/$(TMP_DATA) except $(TRIPLE)
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name $(TRIPLE) ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" -name '*php' -prune -print -exec rm -rf {} ";"
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)
	# strip binaries
	find "/tmp/$(TMP_DATA)" -type f -perm +a+x -exec $(STRIP) {} \;
	# create Receipts file
	mkdir -p /tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts && echo $(DEBIAN_VERSION) >/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dev_@_$(DEBIAN_ARCH).deb
	# write protect and pack data.tar.gz
	chmod -Rf a-w "/tmp/$(TMP_DATA)" || true
	$(TAR) cf - --owner 0 --group 0 -C /tmp/$(TMP_DATA) . | gzip >/tmp/$(TMP_DATA).tar.gz
	ls -l /tmp/$(TMP_DATA).tar.gz
	# create control.tar.gz
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
	  $(F); \
	  [ "$(DEBIAN_DEPENDS)" ] && echo "$(DEBIAN_DEPENDS)" | filter_dependencies "Depends:"; \
	  [ "$(DEBIAN_RECOMMENDS)" ] && echo "$(DEBIAN_RECOMMENDS)" | filter_dependencies "Recommends:"; \
	  echo "Description: $(DEBIAN_DESCRIPTION)"; \
	) >"/tmp/$(TMP_CONTROL)/control"
	if [ "$(strip $(DEBIAN_CONTROL))" ]; then for i in $(DEBIAN_CONTROL); do cp $$i /tmp/$(TMP_CONTROL)/$${i##*.}; done; fi
	$(TAR) cvf - $(DEBIAN_CONTROL) --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) . | gzip >/tmp/$(TMP_CONTROL).tar.gz
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

"$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb":
	# make debian debugging package $(DEBIAN_PACKAGE_NAME)-dbg_$(DEBIAN_VERSION)_$(DEBIAN_ARCH).deb
	# FIXME: make also dependent on location (i.e. public */Frameworks/ only)
ifeq ($(WRAPPER_EXTENSION),framework)
	mkdir -p "$(DEBDIST)/binary-$(DEBIAN_ARCH)" "$(DEBDIST)/archive"
	# copy again including Headers
	chmod -Rf u+w "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)" || true
	$(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf - && wait && echo done)
	# remove foreign architectures in /tmp/$(TMP_DATA) except $(TRIPLE)
	find "/tmp/$(TMP_DATA)" "(" -name '*-linux-gnu*' ! -name $(TRIPLE) ")" -prune -print -exec rm -rf {} ";"
	find "/tmp/$(TMP_DATA)" -name '*php' -prune -print -exec rm -rf {} ";"
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(CONTENTS)/$(PRODUCT_NAME)
	rm -rf /tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)/$(NAME_EXT)/$(PRODUCT_NAME)
	# create Receipts file
	mkdir -p /tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts && echo $(DEBIAN_VERSION) >/tmp/$(TMP_DATA)/$(EMBEDDED_ROOT)/Library/Receipts/$(DEBIAN_PACKAGE_NAME)-dbg_@_$(DEBIAN_ARCH).deb
	# write protect and pack data.tar.gz
	chmod -Rf a-w "/tmp/$(TMP_DATA)" || true
	$(TAR) cf - --owner 0 --group 0 -C /tmp/$(TMP_DATA) . | gzip >/tmp/$(TMP_DATA).tar.gz
	ls -l /tmp/$(TMP_DATA).tar.gz
	# create control.tar.gz
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
	  $(F); \
	  [ "$(DEBIAN_DEPENDS)" ] && echo "$(DEBIAN_DEPENDS)" | filter_dependencies "Depends:"; \
	  [ "$(DEBIAN_RECOMMENDS)" ] && echo "$(DEBIAN_RECOMMENDS)" | filter_dependencies "Recommends:"; \
	  echo "Description: $(DEBIAN_DESCRIPTION)"; \
	) >"/tmp/$(TMP_CONTROL)/control"
	if [ "$(strip $(DEBIAN_CONTROL))" ]; then for i in $(DEBIAN_CONTROL); do cp $$i /tmp/$(TMP_CONTROL)/$${i##*.}; done; fi
	$(TAR) cf - $(DEBIAN_CONTROL) --owner 0 --group 0 -C /tmp/$(TMP_CONTROL) . | gzip >/tmp/$(TMP_CONTROL).tar.gz
	- rm -rf $@
	- mv -f "$(DEBDIST)/binary-$(DEBIAN_ARCH)/$(DEBIAN_PACKAGE_NAME)-dbg_"*"_$(DEBIAN_ARCH).deb" "$(DEBDIST)/archive" 2>/dev/null
	ar -r -cSv $@ /tmp/$(TMP_DEBIAN_BINARY) /tmp/$(TMP_CONTROL).tar.gz /tmp/$(TMP_DATA).tar.gz
	ls -l $@
ifeq ($(OPEN_DEBIAN),true)
	open $@
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
	# install_local TRIPLE=$(TRIPLE) DEBIAN_ARCH=$(DEBIAN_ARCH)
ifeq ($(INSTALL),true)
	# INSTALL: $(INSTALL)
	# copy again to /tmp/$(TMP_DATA)
	chmod -Rf u+w "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)" || true
	if [ -d "$(PKG)" ] ; then $(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf - && wait && echo done); fi
	# should we better untar the .deb?
	- : ls -l "$(BINARY)" # fails for tools because we are on the outer level and have included an empty DEBIAN_ARCH in $(BINARY) and $(PKG)
	- [ -x "$(PKG)/../$(PRODUCT_NAME)" ] && cp -f "$(PKG)/../$(PRODUCT_NAME)" "$(PKG)/$(NAME_EXT)/$(PRODUCT_NAME)" || echo nothing to copy # copy potential MacOS binary
ifeq ($(NAME_EXT),bin)
	- if [ -d "$(PKG)" ] ; then $(TAR) cf - --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p '$(HOST_INSTALL_PATH)' && cd '$(HOST_INSTALL_PATH)' && (pwd; chmod -Rf u+w '$(HOST_INSTALL_PATH)/$(NAME_EXT)' 2>/dev/null; $(TAR) xpvf -)); fi
else
	- if [ -d "$(PKG)" ] ; then $(TAR) cf - --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p '$(HOST_INSTALL_PATH)' && cd '$(HOST_INSTALL_PATH)' && (pwd; chmod -Rf u+w '$(HOST_INSTALL_PATH)/$(NAME_EXT)' 2>/dev/null; $(TAR) xpvf - -U --recursive-unlink)); fi
endif
	# installed on localhost at $(HOST_INSTALL_PATH)
else
	# don't install locally
endif

# this one could strip off architectures different from the one to download
# TRIPLE is undefined!
deploy_remote: prepare_temp_files
ifeq ($(DEPLOY),true)
	# DEPLOY: $(DEPLOY)
	# deploy remote
	# copy again to /tmp/$(TMP_DATA)
	chmod -Rf u+w "/tmp/$(TMP_CONTROL)" "/tmp/$(TMP_DATA)" || true
	if [ -d "$(PKG)" ] ; then $(TAR) cf - --exclude .DS_Store --exclude .svn -C "$(PKG)" $(NAME_EXT) | (mkdir -p "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && cd "/tmp/$(TMP_DATA)/$(TARGET_INSTALL_PATH)" && $(TAR) xvf - && wait && echo done); fi
	# download /tmp/$(TMP_DATA) to all devices
	- [ -s "$(DOWNLOAD)" ] && $(DOWNLOAD) -n | while read DEVICE NAME; \
		do \
		$(TAR) cf - --exclude .svn --owner 500 --group 1 -C "/tmp/$(TMP_DATA)" . | gzip | $(DOWNLOAD) $$DEVICE "cd; cd / && gunzip | tar xpvf -" \
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
	# FIXME: how do we know the $(TRIPLE) used to specify the EXECUTABLE_PATH?
	#
	defaults write org.macosforge.xquartz.X11 nolisten_tcp 0; \
	rm -rf /tmp/.X0-lock /tmp/.X11-unix; open -a Xquartz; sleep 5; \
	export DISPLAY=localhost:0.0; [ -x /usr/X11R6/bin/xhost ] && /usr/X11R6/bin/xhost + && \
	RUN_DEVICE=$$($(DOWNLOAD) -r | head -n 1) && \
	[ "$$RUN" ] && [ -x $(DOWNLOAD) ] && $(DOWNLOAD) "$$RUN_DEVICE" \
		"cd; set; export QuantumSTEP=$(EMBEDDED_ROOT); export PATH=\$$PATH:$(EMBEDDED_ROOT)/usr/bin; export LOGNAME=$(LOGNAME); export NSLog=yes; export HOST=\$$(expr \"\$$SSH_CONNECTION\" : '\\(.*\\) .* .* .*'); export DISPLAY=\$$HOST:0.0; set; export EXECUTABLE_PATH=Contents/$(TRIPLE); cd '$(TARGET_INSTALL_PATH)' && $(RUN_CMD) '$(PRODUCT_NAME)' $(RUN_OPTIONS)" \
		|| echo failed to run;
endif
endif
endif

# generic bundle rule

# FIXME: use dependencies to link only if any object file has changed

# replace this by make_binary and make_bundle

# link headers of framework

bundle:
	# create bundle $(PKG)/$(NAME_EXT)
ifeq ($(WRAPPER_EXTENSION),framework)
	[ ! -L "$(PKG)/$(NAME_EXT)/$(CONTENTS)" -a -d "$(PKG)/$(NAME_EXT)/$(CONTENTS)" ] && rm -rf "$(PKG)/$(NAME_EXT)/$(CONTENTS)" || echo nothing to remove # remove directory
	rm -f "$(PKG)/$(NAME_EXT)/$(CONTENTS)" # remove symlink
	(mkdir -p "$(PKG)/$(NAME_EXT)/Versions/$(FRAMEWORK_VERSION)" && ln -sf $(FRAMEWORK_VERSION) "$(PKG)/$(NAME_EXT)/$(CONTENTS)")	# link Current to -> $(FRAMEWORK_VERSION)
endif

headers:
	# create headers $(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers
ifeq ($(WRAPPER_EXTENSION),framework)
ifneq ($(strip $(HEADERSRC)),)
# included header files $(HEADERSRC)
#	$(TAR) -cf /dev/null --transform='s|Source/||;s|Sources/||;s|src/||' --verbose --show-transformed-names $(HEADERSRC)
	- (mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" && $(TAR) -cf - --transform='s|Source/||;s|Sources/||;s|src/||' $(HEADERSRC) | (cd "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Headers" && $(TAR) xf -) )	# copy headers keeping subdirectory structure
endif
	- (mkdir -p "$(EXEC)/Headers" && rm -f $(HEADERS) && ln -sf ../../Headers "$(HEADERS)")	# link to Headers to find <Framework/File.h>
endif
ifeq ($(TRIPLE),darwin-x86_64)
# always use selected system frameworks
else ifeq ($(TRIPLE),MacOS)
# always use system frameworks and make nested frameworks "flat"
	mkdir -p $(TARGET_BUILD_DIR)/$(TRIPLE)
	- for fwk in $(shell find /System/Library/Frameworks -name '*.framework' | sed "s/\.framework//g" ); \
	  do \
	      rm -f $(TARGET_BUILD_DIR)/$(TRIPLE)/$$(basename $$fwk); \
		  ln -sf $$fwk/Versions/Current/Headers $(TARGET_BUILD_DIR)/$(TRIPLE)/$$(basename $$fwk) \
	  ; done
endif

resources: bundle
	chmod -Rf u+w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/" 2>/dev/null || true # unprotect resources
# copy resources to $(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources
ifneq ($(WRAPPER_EXTENSION),)
# included resources $(INFOPLISTS) $(RESOURCES)
	- mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)"
ifneq ($(strip $(INFOPLISTS)),)
# should reject multiple Info.plists
# should expand ${EXECUTABLE_NAME} and other macros!
	- sed 's/$${EXECUTABLE_NAME}/$(EXECUTABLE_NAME)/g; s/$${MACOSX_DEPLOYMENT_TARGET}/10.0/g; s/$${PRODUCT_NAME:rfc1034identifier}/$(PRODUCT_NAME)/g; s/$${PRODUCT_NAME:identifier}/$(PRODUCT_NAME)/g; s/$${PRODUCT_NAME}/$(PRODUCT_NAME)/g; s/$$(PRODUCT_BUNDLE_IDENTIFIER)/$(PRODUCT_BUNDLE_IDENTIFIER)/g' <"$(INFOPLISTS)" >"$(PKG)/$(NAME_EXT)/$(CONTENTS)/Info.plist"
else
# create a default Info.plist
	- (echo "CFBundleName = $(PRODUCT_NAME);"; echo "CFBundleExecutable = $(EXECUTABLE_NAME);") >"$(PKG)/$(NAME_EXT)/$(CONTENTS)/Info.plist"
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
	chmod -R a-w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/Resources/"* 2>/dev/null || true	# write protect resources

"$(BINARY)":: bundle headers $(OBJECTS)
	# PHPSRCS: $(PHPSRCS)
ifeq ($(TRIPLE),php)
ifneq ($(strip $(PHPSRCS)),)
	for PHP in $(PHPSRCS); \
	do \
		if [ -r "$$PHP" ]; \
		then \
			mkdir -p "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php" && \
			php -l "$$PHP" && \
			chmod -Rf u+w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/"; \
			cp -pf "$$PHP" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/" && \
			cp -pf "$$PHP" "$(BINARY)" && \
			chmod -R a-w "$(PKG)/$(NAME_EXT)/$(CONTENTS)/php/"; \
		fi; \
		done
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
ifeq ($(TRIPLE),darwin-x86_64)
	- ln -sf "$(TRIPLE)/lib$(EXECUTABLE_NAME).$(SO)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(EXECUTABLE_NAME)"	# create link to MacOS version
else ifeq ($(TRIPLE),MacOS)
	- ln -sf "$(TRIPLE)/lib$(EXECUTABLE_NAME).$(SO)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(EXECUTABLE_NAME)"	# create link to MacOS version
else
	- ln -sf "lib$(EXECUTABLE_NAME).$(SO)" "$(PKG)/$(NAME_EXT)/$(CONTENTS)/$(TRIPLE)/$(EXECUTABLE_NAME)"	# create libXXX.so entry for ldconfig
endif
endif
endif

"$(EXEC)":: bundle headers resources
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
	# LIBS: $(LIBS)
	# BINARY: $(BINARY)
	# RESOURCES: $(RESOURCES)
	# HEADERS: $(HEADERSRC)
	# INFOPLISTS: $(INFOPLISTS)
	mkdir -p "$(EXEC)"

# EOF
