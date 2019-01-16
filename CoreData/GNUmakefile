# The main makefile of the GNUstep Core Data framework.
# Copyright (C) 2005 Free Software Foundation, Inc.
#
# Written by:  Saso Kiselkov <diablos@manga.sk>
# Date: August 2005
#
# This file is part of the GNUstep Core Data framework.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(warning )
    $(warning Unable to obtain GNUSTEP_MAKEFILES setting from gnustep-config!)
    $(warning Perhaps gnustep-make is not properly installed,)
    $(warning so gnustep-config is not in your PATH.)
    $(warning )
    $(warning Your PATH is currently $(PATH))
    $(warning )
  endif
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif


include $(GNUSTEP_MAKEFILES)/common.make

PROJECT_NAME=CoreData
FRAMEWORK_NAME=$(PROJECT_NAME)

$(PROJECT_NAME)_OBJC_FILES=$(wildcard *.m)
$(PROJECT_NAME)_HEADER_FILES=$(filter-out CoreDataUtilities.h, $(wildcard *.h))

$(PROJECT_NAME)_RESOURCE_FILES=$(wildcard Resources/*)

$(PROJECT_NAME)_LANGUAGES=$(basename $(wildcard *.lproj))
$(PROJECT_NAME)_LOCALIZED_RESOURCE_FILES=$(sort $(notdir $(wildcard *.lproj/*)))

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/framework.make
-include GNUmakefile.postamble
