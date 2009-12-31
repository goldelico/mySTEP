/* part of ocpp - an obj-c preprocessor */

struct Node 
{
	int type;
	char *name;
	struct Node *left;
	struct Node *right;
	struct Node *next;
};

int node(int type, const char *name);
int node1(int type, int left, int right);
