/* part of objc2pp - an obj-c 2 preprocessor */

#import "AST.h"

@implementation Node 

- (id) initWithName:(const char *) n type:(int) t
{
	if((self=[super init]))
		{
		if(n)
			name=strdup(n);
		type=t;
		// add to map table(s)
		}
	return self;
}

- (void) dealloc
{
	if(name)
		free((void *) name);
	[left release];
	[right release];
	// remove from map table(s)
	[super dealloc];
}

- (int) type;
{
	return type;
}

- (const char *) name;
{
	return name;
}

- (Node *) left;
{
	return left;
}

- (Node *) right;
{
	return right;
}

- (void) setLeft:(Node *) n;
{
	[left autorelease];
	left=[n retain];
}

- (void) setRight:(Node *) n;
{
	[right autorelease];
	right=[n retain];
}

- (void) setType:(Class) type;
{
	
}

- (void) process
{ // process this node
	[self print];	
}

@end

/* parser interface methods */

#include "node.h"

/// FIXME: can we use the Node's -hash value as the integer id ???
/// FIXME: and use a NSMapTables to map from int back to Node object

Node **nodes;

static int nodecount, nodecapacity;

static Node *get(int node)
{
	if(node <= 0 || node > nodecount)
		return nil;
	return nodes[node-1];	/* nodes start counting at 1 */
}

int leaf(int type, const char *name)
{ /* create a leaf node */
	int n;
	if(nodecount >= nodecapacity)
		{ /* (re)alloc */
			if(nodecapacity == 0)
				{ /* first allocation */
					nodecapacity=100;
					nodes=malloc(nodecapacity*sizeof(Node *));
				}
			else
				{
				nodecapacity=2*nodecapacity+10;	/* exponentially increase available capacity */
				nodes=realloc(nodes, nodecapacity*sizeof(Node *));
				}
		}
	nodes[nodecount++]=[[Node alloc] initWithName:name type:type];	/* create new entry */
	return nodecount;	/* returns node index + 1 */
}

int node(int type, int left, int right)
{ /* create a binary node */
	int n=leaf(type, NULL);
	Node *node = get(n);
	[node setLeft:get(left)];
	[node setRight:get(right)];
	return n;
}

int type(int node)
{
	return [get(node) type];
}

const char *name(int node)
{
	return [get(node) name];
}

void process(int node)
{ // called for each declaration
	[get(node) process];
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
