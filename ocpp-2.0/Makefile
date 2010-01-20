YFLAGS  = -dv -t -b y
CFLAGS  = -O
LFLAGS  =
LEX		= flex
YACC	= bison

SRC		= gram.y scan.l main.c
OBJ		= gram.o scan.o main.o
BIN		= /usr/share/QuantumSTEP/Developer/bin/ocpp20

all:	$(BIN) test

$(BIN): $(OBJ)
	cc $(CFLAGS) -o $(BIN) $(OBJ)

scan.o:	y.tab.h

test:
	@echo "*** test 1 ***"
	cpp -P -xc main.c | tee test1.i | $(BIN)
	@echo "*** test 2 ***"
	cpp -P -xobjective-c test.m | tee test2.i | $(BIN)
	@echo "*** test 3 ***"
	# fixme - disable standard Cocoa framework include paths!
	cpp -P -I../Foundation/Headers -xobjective-c ../Foundation/Sources/NSArray.m | tee test3.i | $(BIN)
	@echo "*** tests done ***"

clean:
	rm -rf build y.tab.h y.output *.o
	
src:	clean
	tar cvzf ocpp20.tgz Makefile *.m *.y *.c *.l *.xcodeproj ToDo

