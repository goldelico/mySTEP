/* part of objc2pp - an obj-c 2 preprocessor */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "node.h"

struct Node 
{ /* internal structure */
	int type;
	char *name;
	int left;
	int right;
	int next;
} *nodes;

static int nodecount, nodecapacity;

static struct Node *get(int node)
{
	if(node <= 0 || node > nodecount)
		return NULL; /* error */
	return &nodes[node-1];	/* nodes start counting at 1 */
}

int leaf(int type, const char *name)
{ /* create a leaf node */
	int n;
	struct Node *node;
	if(nodecount >= nodecapacity)
		{ /* (re)alloc */
			if(nodecapacity == 0)
				{ /* first allocation */
					nodecapacity=100;
					nodes=malloc(nodecapacity*sizeof(struct Node));
				}
			else
				{
				nodecapacity=2*nodecapacity+10;	/* exponentially increase available capacity */
				nodes=realloc(nodes, nodecapacity*sizeof(struct Node));
				}
		}
	node=&nodes[nodecount++];	/* next free node */
	node->type=type;
	if(name)
		node->name=strdup(name);
	else
		node->name=NULL;
	node->left=node->right=0;
	node->next=0;
	return nodecount;	/* returns node index + 1 */
}

int node(int type, int left, int right)
{ /* create a binary node */
	int n=leaf(type, NULL);
	struct Node *node = get(n);
	node->left=left;
	node->right=right;
	return n;
}

void dealloc(int n)
{
	if(n)
		{
		struct Node *node = get(n);
		dealloc(node->left);
		dealloc(node->right);
		/*
		 free(node->name);
		 free(node);
		 */		
		}
}

int left(int node)
{
	return get(node)->left;
}

void setLeft(int node, int left)
{
	get(node)->left=left;
}

int right(int node)
{
	return get(node)->right;
}

void setRight(int node, int right)
{
#if 1
	printf("setRight(");
	emit(node);
	printf(", ");
	emit(right);
	printf("\n");
#endif
	get(node)->right=right;
}

int type(int node)
{
	return get(node)->type;
}

void setType(int node, int type)
{
	get(node)->type=type;
}

char *name(int node)
{
	return get(node)->name;
}

/* list */

int list(void)
{ // create a list object
	return leaf(0, NULL);	// dummy...
}

int first(int list)
{ // get first entry of a list
	return get(list)->next;
}

int next(int node)
{
	return get(node)->next;
}

/* static? */ void setNext(int node, int next)
{
	get(node)->next=next;
}

int nth(int list, int n)
{ // get n-th entry of a list
	int r=first(list);
	while(n-- > 0)
		r=next(r);
	return r;
}

int count(int list)
{ // count elements in a list
	int r=first(list);
	int c=0;
	while(r != 0)
		c++, r=next(r);
	return c;	
}

int push(int lifo, int node)
{ // add to lifo (first entry)
	setNext(node, first(lifo));	// attach current first object
	setNext(lifo, node);	// make it the new first
}

int pop(int lifo)
{ // pop first entry
	int r=first(lifo);
	if(r)
		setNext(lifo, next(r));	// remove from LIFO
	return r;
}

/* dictionary */

int dictionary(void)
{
	return leaf(0, NULL);	// dummy...
}

/* FIXME: somehow attach the hash table and linked lists to the dictionary object */

static int symtab[11*19];	// hashed start into linked lists

int lookup(int table, char *word)
{ // look up identifier
	int hash=0;
	char *h=word;
	int s;
	while(*h)
		hash=2*hash+(*h++);
	hash%=sizeof(symtab)/sizeof(symtab[0]);
	s=symtab[hash];	// get first entry
	while(s)
		{
		if(strcmp(name(s), word) == 0)
			return s;	// found
		s=next(s);	// go to next symtab node
		}
	s=leaf(0, word);	// create new entry
	setNext(s, symtab[hash]);
	symtab[hash]=s;	// prepend new entry
	return s;
}

char *keyword(int table, int t)
{ // look up keyword for given type
	int i;
	for(i=0; i<sizeof(symtab)/sizeof(symtab[0]); i++)
		{
		int s=symtab[i];
		while(s)
			{
			if(type(s) == t)
				return name(s);	// type code found - print symbol
			s=next(s);	// go to next symtab node
			}
		}
	return NULL;
}
