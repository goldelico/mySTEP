/* part of objc2pp - an obj-c 2 preprocessor */

// tree node management wrapper

int leaf(int type, const char *name);		// create a leaf
int node(int type, int left, int right);	// create a node

int type(int node);
const char *name(int node);
void setType(int node, int type);	// used for handling keywords

void process(int node);	// called for each declaration

// list object (may be build from nodes or implemented differently)

int list(void);			// create a list object
int first(int list);	// get first entry of a list
int next(int node);		// get next entry (if available)
// void setNext(int node, int next); -- not public!
int nth(int list, int n);		// get n-th entry of a list
int count(int list);			// count elements in a list
int push(int lifo, int node);	// add to lifo (first entry)
int pop(int lifo);				// pop first entry

// symbol table lookup

int dictionary(void);	// create a (hashed) dictionary object
int lookup(int dictionary, char *word);	// look up word and return (if not yet found a fresh) node
char *keyword(int dictionary, int t);	// reverse look up of keyword for object with type t (NULL if not found)

