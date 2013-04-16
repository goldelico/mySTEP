// very special things

@class MyClass;

/* there can be white space between @ and the command */

@ interface MyClass
{
	/* does not raise an error */
	int MyClass;
	/* these are not treated as keywords here */
	int in, byref;
	/* but int do, for; fails */
}

/* static vars, functions, types etc. can be declared at almost any position */

static int var;

@end

/* we can't redefine id/BOOL on a global scope! They just predefined typedefs in /usr/include/objc/objc.h */

#if 0
int SEL;	// SEL redeclared as different kind of symbol
#endif

/* this is accepted because it is not different */

typedef signed char BOOL;

@implementation MyClass

/* keywords can be used in selector components */
/* but can't be used for variable names! e.g. for:(int) byref fails */

- (oneway byref id) for:(int) x do:(int) y byref:(int) z

/* methods can have an ; before the body starts (while functions can't) */

;
{
	/* id can be overwritten by a local typedef */
	typedef char *id;
	id here="string";
	/* BOOL as well */
	struct {
		/* we can use id as a struct component name */
		int id;
	} BOOL;
	BOOL.id=5;
	/* there can be local typedefs overwriting global names */
	{
		typedef long var;
		var somevar=5;
		/* and we can redefine a local type */
		{
			char var='x';
		}
	}
}

@end
