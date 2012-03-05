/* part of objc2pp - an obj-c 2 preprocessor */

// control flags for the scanner

extern int nokeyword;	// if set to 1 an IDENTIFIER is always returned (even if it looks like a keyword)
extern int objctype;	// if 1, identifiers like BOOL, id, SEL are decoded; otherwise they are always reported as IDENTIFIER

extern void pushscope();	// start a new local variable scope
extern void popscope();		// pop scope

// tree node management wrapper so that we can use integers as production values in the grammer

int leaf(int type, const char *name);		// create a leaf
int node(int type, int left, int right);	// create a node

int type(int node);
const char *name(int node);
void setType(int node, int type);	// used for handling keywords
int left(int node);
int right(int node);

void process(int node);	// called for each declaration

// list object (may be build from nodes or implemented differently)

int list(void);			// create a list object
int first(int list);	// get first entry of a list
int next(int node);		// get next entry (if available)
int nth(int list, int n);		// get n-th entry of a list
int count(int list);			// count elements in a list
int push(int lifo, int node);	// add to lifo (first entry)
int pop(int lifo);				// pop first entry

// symbol table lookup

int dictionary(void);	// create a (hashed) dictionary object
int lookup(int dictionary, const char *word, int type);	// look up word and return node; if type>0 not found return a fresh node with given type 
char *keyword(int dictionary, int t);	// reverse look up of keyword for object with type t (NULL if not found)

