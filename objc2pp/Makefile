YFLAGS  = -d -b y
# enable debug:
YFLAGS  = -v -t -d -b y

CFLAGS  = -O
LFLAGS  =
LEX		= flex
YACC	= bison

all: build/scan.m build/gram.m

build/scan.m:	scan.l y.tab.h
	flex  -t $< > build/scan.m

y.tab.h build/gram.m:	gram.y
	bison $(YFLAGS) $<
	mv y.tab.c build/gram.m
