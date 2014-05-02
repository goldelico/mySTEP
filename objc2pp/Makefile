#### OLD ####

YFLAGS  = -d -b y
# enable debug:
YFLAGS  = -v -t -d -b y

CFLAGS  = -O
LFLAGS  =
LEX		= flex
YACC	= bison

all: build/scan.m build/gram.m
	(cd build; ln -sf ../node.h .)

build/y.tab.h build/gram.m:	gram.y
	(cd build; bison $(YFLAGS) ../$<)
	sed 's-y.tab.c-build/gram.m-g' <build/y.tab.c >build/gram.m

build/scan.m:	scan.l build/y.tab.h
	flex -o build/scan.m $<
