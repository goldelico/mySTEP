#### run this if anything was changed in scan.lm or gram.ym ####
#### compiling *.l, *.lm, *.y, and *.ym shoudl be done by mySTEP.make but isn't yet ####

YFLAGS  = -d -b y
# enable debug:
YFLAGS  = -v -t -d -b y

CFLAGS  = -O
LFLAGS  =
LEX		= flex
YACC	= bison

all: build/scan.m build/gram.m
	# (cd build; ln -sf ../node.h .)
	(echo "/* DO NOT EDIT - generated from scan.lm */"; sed 's|y.tab.hm|y.tab.h|g' build/scan.m) > scan.m
	(echo "/* DO NOT EDIT - generated from gram.lm */"; echo "extern int yylex (void);"; sed 's|y.tab.hm|y.tab.h|g' build/gram.m) > gram.m
	(echo "/* DO NOT EDIT - generated from gram.lm */"; cat build/y.tab.hm) > y.tab.h

build/y.tab.h build/gram.m:	gram.ym
	(mkdir -p build; cd build; bison $(YFLAGS) -Wno-other ../$<)
	sed 's|y.tab.c|gram.m|g' <build/y.tab.cm >build/gram.m

build/scan.m:	scan.lm build/y.tab.h
	flex -o build/scan.m $<
