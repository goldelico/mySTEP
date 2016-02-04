/* 
   NSAutoreleasePool.m

   Implementation of auto release pool for delayed disposal.

   Copyright (C) 1995, 1996, 1997 Free Software Foundation, Inc.
   
   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	January 1995
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#include <limits.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>
#import <Foundation/NSThread.h>

#define INITIAL_POOL_SIZE 32	// size of the first _released array.

// Each pool holds it's objects to be 
// released in a linked-list of these
// structures.

struct autorelease_array_list 
{
	struct autorelease_array_list *next;
	unsigned size;
	unsigned count;
	id objects[0];
};

								// When `NO', autoreleased objects are not 
								// actually recorded in an NSAutoreleasePool, 
								// and are not sent a `release' message.
static BOOL __autoreleaseEnabled = YES;
static IMP __allocImp;
static IMP __initImp;
								// When the _released_count of a pool gets over 
								// this value, we raise an exception.  This can 
								// be adjusted with -setPoolCountThreshhold 
static unsigned __poolCountThreshold = UINT_MAX;

				// access to thread variables belonging to NSAutoreleasePool.
#define THREAD_VARS (&(((NSThread*)objc_thread_get_data())->_autorelease_vars))

								// Functions for managing a per-thread cache of 
								// NSAutoreleasedPool's already alloc'ed.  The 
								// cache is kept in the autorelease_thread_var 
static inline void				// structure, which is an ivar of NSThread.
init_pool_cache (struct autorelease_thread_vars *tv)
{
	tv->pool_cache_size = 32;
	tv->pool_cache_count = 0;
	tv->thread_in_dealloc = NO;
	OBJC_MALLOC (tv->pool_cache, id, tv->pool_cache_size);
}

static void
push_pool_to_cache (struct autorelease_thread_vars *tv, id p)
{
	if (!tv->pool_cache)
		init_pool_cache (tv);
	else 
		if (tv->pool_cache_count == tv->pool_cache_size)
			{
			tv->pool_cache_size *= 2;
			OBJC_REALLOC (tv->pool_cache, id, tv->pool_cache_size);
			}

	tv->pool_cache[tv->pool_cache_count++] = p;
}

static id
pop_pool_from_cache (struct autorelease_thread_vars *tv)
{
	return tv->pool_cache[--(tv->pool_cache_count)];
}

@implementation NSAutoreleasePool

+ (void) initialize
{
	if (self == [NSAutoreleasePool class])
		{
		objc_thread_set_data([NSThread new]);	// configure the main thread
		__allocImp = [self methodForSelector: @selector(allocWithZone:)];
		__initImp = [self instanceMethodForSelector: @selector(init)];
		}
}

+ (id) allocWithZone:(NSZone *) z
{				
	struct autorelease_thread_vars *tv = THREAD_VARS;
												// if an existing autorelease  
	if (tv && tv->pool_cache_count)					// pool is available return it
		return pop_pool_from_cache (tv);		// instead of alloc'ing a new

	return (id) NSAllocateObject(self, 0, z);
}

+ (id) new
{
	id arp = (*__allocImp)(self, @selector(allocWithZone:), NSDefaultMallocZone());
	return (*__initImp)(arp, @selector(init));
}

// this are private methods!
+ (void) enableRelease:(BOOL)enable			{ __autoreleaseEnabled = enable; }
+ (void) setPoolCountThreshhold:(unsigned)c	{ __poolCountThreshold = c; }
+ (void) enableDoubleReleaseCheck:(BOOL)en	{ }
- (oneway void) release						{ [self dealloc]; }

- (NSString *) description; { return [NSString stringWithFormat:@"%p %@ released:%u", self, NSStringFromClass([self class]), _released_count]; }

- (id) init
{
	struct autorelease_thread_vars *tv;
										// Allocate the array that will be the
	if (!_released_head)				// new head of the list of arrays.
		{
		_released = (struct autorelease_array_list*)
					objc_malloc (sizeof(struct autorelease_array_list) + 
					(INITIAL_POOL_SIZE * sizeof(id)));
										// Initially there is no NEXT array in 
		_released->next = NULL;			// the list, so NEXT == NULL.
		_released->size = INITIAL_POOL_SIZE;
		_released->count = 0;
		_released_head = _released;
		}
	else								// Already initialized; (it came from
		{								// autorelease_pool_cache); we don't 
		_released = _released_head;		// have to allocate new array list 
		_released->count = 0;			// memory.
		}

	_released_count = 0;						// Pool is initially empty

	tv = THREAD_VARS;
	_child = nil;
	if((_parent = tv->current_pool))			// Install self as current pool
		tv->current_pool->_child = self;
	tv->current_pool = self;
#if 0
	fprintf(stderr, "new ARP %p\n", self);
#endif
	return self;
}

+ (void) addObject:(id)anObj
{
	NSAutoreleasePool *pool = THREAD_VARS->current_pool;
	if (pool)
		[pool addObject: anObj];
	else
		{
		NSAutoreleasePool *arp = [NSAutoreleasePool new];

		if (anObj)
			NSLog(@"autorelease called without pool for object (%@) \
					of class %s\n", anObj, 
					[NSStringFromClass([anObj class]) cString]);
		else
			NSLog(@"autorelease called without pool for nil object.\n");
		[arp release];
		}
}

- (void) addObject:(id)anObj
{
#if 0
	[anObj class];	// objects put into the ARP should be able to respond to messages
#endif
	if (!__autoreleaseEnabled)		// do nothing if global, static variable 
		return;						// AUTORELEASE_ENABLED is not set
#if 0
	fprintf(stderr, "autorelease %p\n", anObj);
#endif
	if (_released_count >= __poolCountThreshold)
		[NSException raise: NSGenericException
					 format: @"AutoreleasePool count threshold exceeded."];
												// Get new array for the list,  
	if (_released->count == _released->size)	// if the current one is full.
		{
		if (_released->next)				// There is an already-allocated
			{			 					// one in the chain; use it. 
			_released = _released->next;
			_released->count = 0;
			}
		else								// We are at the end of the chain, 
			{								// and need to allocate a new one.
	  		struct autorelease_array_list *new_released;
	 		unsigned new_size = _released->size * 2;
	  
	  		new_released = (struct autorelease_array_list*)
					objc_malloc(sizeof(struct autorelease_array_list) 
									+ (new_size * sizeof(id)));
			new_released->next = NULL;
			new_released->size = new_size;
			new_released->count = 0;
			_released->next = new_released;
			_released = new_released;
			}
		}
											// Put object at end of the list
	_released->objects[_released->count] = anObj;
	(_released->count)++;					// Keep track of the total number  
											// of objects autoreleased across
	THREAD_VARS->total_objects_count++;		// all pools.
										 
	_released_count++;						// Track total number of objects
}											// autoreleased in this pool

- (void) _dealloc							// actually dealloc this auto pool
{
	struct autorelease_array_list *a;
#if 0
	fprintf(stderr, "ARP dealloc %p\n", self);
#endif
	for (a = _released_head; a;)
		{
		void *n = a->next;
		objc_free(a);
		a = n;
		}
	[super dealloc];
}

- (void) dealloc
{
	struct autorelease_array_list *released;
	struct autorelease_thread_vars *tv;
	NSAutoreleasePool **cp;	
	// If there are NSAutoreleasePools below us in the
	// stack of NSAutoreleasePools, then deallocate
	// them also.  The (only) way we could get in this 
	// situation (in correctly written programs, that
	// don't release NSAutoreleasePools in weird ways),
	// is if an exception threw us up the stack.
#if 0
	fprintf(stderr, "arp dealloc %p - initial memory=%d\n", self, NSRealMemoryAvailable());
#endif
	if (_child)	
		[_child dealloc];	
    released = _released_head;
	while(released)
		{
		id *p=released->objects;
		id *e=p+released->count;
		while(p < e)
			{
			id anObject;
			if((anObject=*p))
				{
				*p++=nil;	// take out of the list
#if 0
				fprintf(stderr, "ARP: release object %p\n", anObject);
#endif
				[anObject release];
				}
			else
				p++;
			}
		released = released->next;
		}

	tv = THREAD_VARS;							// Uninstall ourselves as the
    cp = &(tv->current_pool);					// current pool; install our 
    *cp = _parent;								// parent pool
    if (*cp)
		(*cp)->_child = nil;

	if(tv->thread_in_dealloc)					// cleanup if thread in dealloc
		{
		[self _dealloc];						// actually dealloc self
		if(!(_parent))							// if no parent we are top pool
			{
			while(tv->pool_cache_count)			// release inactive pools in
				{								// the pools stack cache
				id pool = pop_pool_from_cache(tv);
				[pool _dealloc];
				}
			if (tv->pool_cache)
				objc_free(tv->pool_cache);
			}
		}
	else										// Don't deallocate self, just
    	push_pool_to_cache (tv, self);			// push to cache for later use
#if 0
	fprintf(stderr, "arp dealloc -    done memory=%d\n", NSRealMemoryAvailable());
#endif
	return;
	[super dealloc];	// make compiler happy
}

- (void) drain;
{
	// we should move all from dealloc here so that dealloc simply calls [self drain]; [super dealloc]
	NIMP;
}

- (id) retain
{
	[NSException raise: NSGenericException
				 format: @"Don't call `-retain' on a NSAutoreleasePool"];
	return self;
}

- (id) autorelease
{
	[NSException raise: NSGenericException
				 format: @"Don't call `-autorelease' on a NSAutoreleasePool"];
	return self;
}

@end
