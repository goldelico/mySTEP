/* part of objc2pp - an obj-c 2 preprocessor */

int leaf(int type, const char *name);
int node(int type, int left, int right);
int type(int node);
void setType(int node, int type);	// used for handling keywords
char *name(int node);
int left(int node);
int right(int node);

// hash table management for symbols
int next(int node);
void setNext(int node, int next);
