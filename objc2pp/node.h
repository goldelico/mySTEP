/* part of ocpp - an obj-c preprocessor */

int leaf(int type, const char *name);
int node(int type, int left, int right);
int left(int node);
int right(int node);
int type(int node);
char *name(int node);
