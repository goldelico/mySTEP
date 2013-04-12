/* part of objc2pp - an obj-c 2 preprocessor */

// control flags for the scanner

extern int nokeyword;	// if set to 1 an IDENTIFIER is always returned (even if it looks like a keyword)
extern int objctype;	// if 1, identifiers like BOOL, id, SEL are decoded; otherwise they are always reported as IDENTIFIER
extern int typename;	// if 1, IDENTIFIERS representing a type name or @class forward declaration are reported as TYPENAME

extern void pushscope();	// start a new local variable scope
extern void popscope();		// pop scope

// tree node management wrapper so that we can use integers as production values in the grammer

int leaf(char *type, const char *value);	// create a leaf node
// int node(char *type, int left, int right);	// create a node
int node(char *type, ...);	// create a node with optional children (0-terminated list)
int append(int list, int node);	// append a node as child
void removelast(int list);

const char *type(int node);
void setType(int node, char *type);	// used for handling keywords
// int left(int node);
// int right(int node);
int value(int node);
const char *stringValue(int node);
void setStringValue(int node, char *value);

void process(int node);	// called for each declaration

// list object (may be build from nodes or implemented differently)

// lists are nodes and objects are stored in children
//int list(void);			// create a list object
//int first(int list);	// get first entry of a list
int last(int list);	// get last of a list
//int next(int node);		// get next entry (if available)
int nth(int list, int n);		// get n-th entry of a list
int count(int list);			// count elements in a list
//void push(int lifo, int node);	// add to end of list
//void pop(int lifo);				// remove last entry

// symbol table lookup

int dictionary(void);	// create a (hashed) dictionary object
int lookup(int dictionary, const char *word, char *type, int value);	// look up word and return node; if type>0 not found return a fresh leafnode with given type/code 
void setkeyval(int dictionary, const char *key, int value);
// char *keyword(int dictionary, int t);	// reverse look up of keyword for object with type t (NULL if not found)

