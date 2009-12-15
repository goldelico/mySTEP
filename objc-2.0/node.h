struct Node 
{
	int type;
	char *name;
	struct Node *left;
	struct Node *right;
	struct Node *next;
};

int node(int type, const char *name);
