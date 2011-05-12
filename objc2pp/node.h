/* part of objc2pp - an obj-c 2 preprocessor */

// tree node management

int leaf(int type, const char *name);
int node(int type, int left, int right);
void dealloc(int node);

int type(int node);
char *name(int node);
void setType(int node, int type);	// used for handling keywords
int left(int node);
void setLeft(int node, int left);
int right(int node);
void setRight(int node, int right);

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

