# $Id: test.make,v 1.1 2003/11/21 14:44:33 phink Exp $
# Copyright (c) 1997-2000, Sen:te Ltd.  All rights reserved.
#
# Use of this source code is governed by the license in OpenSourceLicense.html
# found in this distribution and at http://www.sente.ch/software/ ,  where the
# original version of this source code can also be found.
# This notice may not be removed from this file.


ifeq "" "$(TEST_SPEC)"
TEST_SPEC = $(NEXT_ROOT)$(LOCAL_DEVELOPER_DIR)/Makefiles/Resources/otestSpec.plist
endif


ifeq "" "$(OTEST)"
ifeq "WINDOWS" "$(OS)"
OTEST = $(NEXT_ROOT)$(LOCAL_DEVELOPER_EXECUTABLES_DIR)/otest.exe
else
OTEST = /usr/local/bin/otest
endif
endif

ifdef APP_WRAPPER_EXTENSION
TESTED = $(PRODUCT_DIR)/$(NAME)
DEFAULT_EXTENSION = $(APP_WRAPPER_EXTENSION)
else
TESTED = $(PRODUCT)
DEFAULT_EXTENSION = 
endif

RECURSABLE_RULES += test

test: all
	$(BUILDFILTER) -command $(OTEST) $(TESTED)$(DEFAULT_EXTENSION) -- $(TEST_SPEC)

test_all: all
	$(BUILDFILTER) -command $(OTEST) -SenTest All $(TESTED)$(DEFAULT_EXTENSION) -- $(TEST_SPEC)


# test_debug target needs a workaround the _debug problem for frameworks and bundles. 
# Uses symlinks to get the right executable name. Links are not removed when tests fails.

# Not all projects announce their PROJTYPE... 
# We consider a loadable bundle the default, app, woapp and tool the exception

TEST_UNDERSCORE_DEBUG = YES
DEBUG_WRAPPER_EXTENSION =

ifeq "TOOL" "$(PROJTYPE)"
DEBUG_WRAPPER_EXTENSION =
TEST_UNDERSCORE_DEBUG = NO
endif

ifdef APP_WRAPPER_EXTENSION
DEBUG_WRAPPER_EXTENSION = .debug
TEST_UNDERSCORE_DEBUG = NO
endif

ifeq "WOAPP" "$(PROJTYPE)"
DEBUG_WRAPPER_EXTENSION = .debug
TEST_UNDERSCORE_DEBUG = NO
endif

ifeq "YES" "$(TEST_UNDERSCORE_DEBUG)"
PRE_DEBUG_TEST = create-sym-clone
POST_DEBUG_TEST = remove-sym-clone
ACTUAL_DEBUG_TEST = actual_test_debug
else
PRE_DEBUG_TEST =
POST_DEBUG_TEST =
ACTUAL_DEBUG_TEST = actual_test_debug
endif


create-sym-clone:
	-$(SYMLINK) $(TESTED)/$(NAME)$(DEBUG_SUFFIX)$(DLL_EXT) $(TESTED)/$(NAME)$(DLL_EXT)

remove-sym-clone:
	-$(SILENT) $(RM) -rf $(TESTED)/$(NAME)$(DLL_EXT)

actual_test_debug:
	$(BUILDFILTER) -command $(OTEST) $(TESTED)$(DEBUG_WRAPPER_EXTENSION) -- $(TEST_SPEC)

test_debug: debug $(PRE_DEBUG_TEST) $(ACTUAL_DEBUG_TEST) $(POST_DEBUG_TEST)

