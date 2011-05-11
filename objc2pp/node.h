/* part of objc2pp - an obj-c 2 preprocessor */

// node management (defined in gram.y)

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

// symbol table objects

int dictionary(void);
int lifo(void);

int first(int table);	// get first entry
int next(int node);		// het next entry (if available)
// void setNext(int node, int next); -- not public!

int push(int lifo, int node);	// add to lifo
int pop(int lifo);		// pop

// symbol table lookup

char *keyword(int symtab, int t);	// look up name for object with type t (NULL if not found)
int lookup(int symtab, char *word);	// look up word and return (optionally fresh) node

