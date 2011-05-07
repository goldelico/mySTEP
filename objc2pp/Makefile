# debug:
# YFLAGS  = -v -t -d -b y
YFLAGS  = -d -b y

CFLAGS  = -O
LFLAGS  =
LEX		= flex
YACC	= bison

SRC		= gram.y scan.l main.c
OBJ		= gram.o scan.o main.o
BIN		= /usr/share/QuantumSTEP/Developer/bin/objc2pp

# OCPP	= cpp -P
OCPP	= cc -E -P
# OCPP	= cc -E -v -H 

all:	$(BIN) test

$(BIN): $(OBJ)
	cc $(CFLAGS) -o $(BIN) $(OBJ)

scan.o:	scan.l y.tab.h
	flex  -t $< > scan.c
	cc $(CFLAGS) -c -o $@ scan.c
	rm scan.c

y.tab.h gram.o:	gram.y
	bison -d -b y $< 
	cc $(CFLAGS) -c -o gram.o y.tab.c
	rm y.tab.c

MYSTEP_SYSROOT :=  -std=c99 -isysroot/usr/share/QuantumSTEP \
	-I/Developer/usr/bin/../lib/gcc/i686-apple-darwin10/4.2.1/include \
	-I/usr/local/include \
	-I/usr/lib/gcc/i686-apple-darwin10/4.2.1/include \
	-I/usr/include

test:
	@echo "*** test 1 ***"
	$(OCPP) simple.m | tee test1.i | $(BIN) | tee test1.c
	@echo "*** test 2 ***"
	$(OCPP) main.c | tee test2.i | $(BIN) | tee test2.c
	@echo "*** test 3 ***"
	$(OCPP) test.m | tee test3.i | $(BIN) | tee test3.c
	@echo "*** test 4 ***"
	# disable standard Cocoa framework include paths so that we can (pre)process mySTEP sources
	$(OCPP) $(MYSTEP_SYSROOT) ../Foundation/Sources/NSArray.m | tee test4.i | $(BIN) | tee test4.c
	@echo "*** tests done ***"

clean:
	rm -rf build y.tab.h y.output *.o
	
src:	clean
	tar cvzf objc2pp.tgz Makefile *.m *.y *.c *.l *.xcodeproj ToDo

