# GNUmakefile
#
# Main makefile of the DataBuilder application.
#
# Copyright (C) 2005  Saso Kiselkov
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME=DataBuilder

$(APP_NAME)_OBJC_FILES=$(wildcard *.m)
$(APP_NAME)_RESOURCE_FILES=\
$(wildcard Resources/*) \
$(wildcard Images/*)

$(APP_NAME)_LANGUAGES=$(basename $(wildcard *.lproj))
$(APP_NAME)_LOCALIZED_RESOURCE_FILES=$(sort $(notdir $(wildcard *.lproj/*)))

ADDITIONAL_GUI_LIBS += -lCoreData

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
