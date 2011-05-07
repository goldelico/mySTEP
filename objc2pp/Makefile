# debug:
# YFLAGS  = -dv -t -b y
YFLAGS  = -b y

CFLAGS  = -O
LFLAGS  =
LEX		= flex
YACC	= bison

SRC		= gram.y scan.l main.c
OBJ		= gram.o scan.o main.o
BIN		= /usr/share/QuantumSTEP/Developer/bin/objc2pp

OCPP	= cpp -P

all:	$(BIN) test

$(BIN): $(OBJ)
	cc $(CFLAGS) -o $(BIN) $(OBJ)

scan.o:	y.tab.h

test:
	@echo "*** test 1 ***"
	$(OCPP) -xc simple.m | tee test1.i | $(BIN) | tee test1.c
	@echo "*** test 2 ***"
	$(OCPP) -xc main.c | tee test2.i | $(BIN) | tee test2.c
	@echo "*** test 3 ***"
	$(OCPP) -xobjective-c test.m | tee test3.i | $(BIN) | tee test3.c
	@echo "*** test 4 ***"
	# fixme - disable standard Cocoa framework include paths!
	$(OCPP) -nostdinc -xobjective-c -isysroot=../../../.. -I/include -I/usr/include -I../Foundation/Headers ../Foundation/Sources/NSArray.m | tee test4.i | $(BIN) | tee test4.c
	@echo "*** tests done ***"

clean:
	rm -rf build y.tab.h y.output *.o
	
src:	clean
	tar cvzf objc2pp.tgz Makefile *.m *.y *.c *.l *.xcodeproj ToDo

