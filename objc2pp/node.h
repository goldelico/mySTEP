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

// hash table management for symbols
int next(int node);
void setNext(int node, int next);

// symbol table (defined in scan.l)

char *keyword(int t);
int lookup(char *word);
