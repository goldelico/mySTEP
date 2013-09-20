/* 
   NSNotificationQueue.m

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#import <Foundation/NSRunLoop.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>

typedef struct _InstanceList {
    struct _InstanceList *next;
    struct _InstanceList *prev;
    id queue;
} InstanceList;

typedef struct _NSNotificationQueue_t {
	@defs(NSNotificationQueue)
} NSNotificationQueue_t;

// Class variables
static InstanceList *__notificationQueues = NULL;
static NSNotificationQueue *__defaultQueue = nil;

/*
	Queue layout

	Queue             Elem              Elem              Elem
	  head ---------> prev -----------> prev -----------> prev --> nil
			  nil <-- next <----------- next <----------- next
	  tail --------------------------------------------->
*/


@interface GSQueueRegistration : NSObject
{
@public
    GSQueueRegistration *next;
    GSQueueRegistration *prev;
    NSNotification *notification;
    id name;
    id object;
    NSArray *modes;
}

@end
@implementation GSQueueRegistration
@end

typedef struct _NSNotificationQueueList {
    GSQueueRegistration *head;
    GSQueueRegistration *tail;
} NSNotificationQueueList;

@interface NSNotification (NSPrivate)

- (void) _addToQueue:(NSNotificationQueueList *)queue 
		 	forModes:(NSArray *)modes;

@end

@implementation NSNotification (NSPrivate)

- (void) _addToQueue:(NSNotificationQueueList *)queue 
		 	forModes:(NSArray *)modes
{
	if(!_queued)
		_queued = [GSQueueRegistration new];
	else
		if(((GSQueueRegistration *)_queued)->notification != nil)
			{
			NSLog(@"warning: notification %@ to be queued is already in queue\n", self);
			return;
			}

	((GSQueueRegistration *)_queued)->notification = [self retain];
	((GSQueueRegistration *)_queued)->name = _name;
	((GSQueueRegistration *)_queued)->object = _object;
	if(modes)
		((GSQueueRegistration *)_queued)->modes = [modes copy];
	((GSQueueRegistration *)_queued)->prev = NULL;
	((GSQueueRegistration *)_queued)->next = queue->tail;
	queue->tail = _queued;

	if (((GSQueueRegistration *)_queued)->next)
		((GSQueueRegistration *)_queued)->next->prev = _queued;
	if (!queue->head)
		queue->head = _queued;
}		

@end


static void
GSRemoveFromQueue(NSNotificationQueueList *queue, GSQueueRegistration *item)
{
    if (item->prev)
			item->prev->next = item->next;
    else if ((queue->tail = item->next))
	    item->next->prev = NULL;

    if (item->next)
			item->next->prev = item->prev;
    else if ((queue->head = item->prev))
	    item->prev->next = NULL;

	if (item->modes)
		[item->modes release];
	[item->notification release];
	item->notification = nil;
}

@implementation NSNotificationQueue

+ (void) initialize
{
 	if (!__defaultQueue)
		__defaultQueue = [[self alloc] init];
}

+ (NSNotificationQueue*) defaultQueue		{ return __defaultQueue; }

- (id) init
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    return [self initWithNotificationCenter: nc];
}

- (id) initWithNotificationCenter:(NSNotificationCenter*)notificationCenter
{
	InstanceList *regItem;

    _center = [notificationCenter retain];					// init queue
    _asapQueue = objc_calloc(1, sizeof(NSNotificationQueueList));
    _idleQueue = objc_calloc(1, sizeof(NSNotificationQueueList));

    regItem = objc_calloc(1, sizeof(InstanceList));			// insert in global 
	regItem->next = __notificationQueues;					// list of queues
	regItem->queue = self;
	__notificationQueues = regItem;

    return self;
}

- (void) dealloc
{
InstanceList *regItem, *theItem;
GSQueueRegistration *item;
InstanceList *queues = __notificationQueues;			// remove from class 
														// instances list
    if (queues->queue == self) 
	    __notificationQueues = __notificationQueues->next;
    else 
		{
		for(regItem=__notificationQueues; regItem->next; regItem=regItem->next)
			if (regItem->next->queue == self) 
				{
				theItem = regItem->next;
				regItem->next = theItem->next;
				objc_free(theItem);
				break;
		}		}
															// release self
    for (item = _asapQueue->head; item; item = item->prev)
			// FIXME: do we leak here? But see also http://savannah.gnu.org/bugs/?25915
			GSRemoveFromQueue(_asapQueue, item);
    objc_free(_asapQueue);

    for (item = _idleQueue->head; item; item=item->prev)
			GSRemoveFromQueue(_idleQueue, item);
    objc_free(_idleQueue);

    [_center release];
    [super dealloc];
}

- (void) dequeueNotificationsMatching:(NSNotification*)notification
						 coalesceMask:(unsigned int)coalesceMask
{												 
GSQueueRegistration *item;					// Inserting and Removing
GSQueueRegistration *next;					// Notifications From a Queue
id name = [notification name];
id object = [notification object];
										// find in ASAP notification in queue
    for (item = _asapQueue->tail; item; item = next) 
		{
		next = item->next;
		if ((coalesceMask & NSNotificationCoalescingOnName)
				&& [name isEqual:item->name]) 
			{
			GSRemoveFromQueue(_asapQueue, item);
			continue;
			}
		if ((coalesceMask & NSNotificationCoalescingOnSender)
				&& (object == item->object))
			{
			GSRemoveFromQueue(_asapQueue, item);
			continue;
		}	}
										// find in idle notification in queue
    for (item = _idleQueue->tail; item; item = next)
		{
		next = item->next;
		if ((coalesceMask & NSNotificationCoalescingOnName)
				&& [name isEqual:item->name])
			{
			GSRemoveFromQueue(_asapQueue, item);
			continue;
			}
		if ((coalesceMask & NSNotificationCoalescingOnSender)
				&& (object == item->object))
			{
			GSRemoveFromQueue(_asapQueue, item);
			continue;
		}	}
}

- (BOOL) postNotification:(NSNotification*)notification
		 		 forModes:(NSArray*)modes
{
	NSString *mode;	// check to see if run loop is in a valid mode
#if 0
	NSLog(@"postNotification: %@ forModes: %@", notification, modes);
#endif
    if (!modes || !(mode = [[NSRunLoop currentRunLoop] currentMode]) || [modes containsObject:mode])	// if no modes (i.e. all) or specific mode is valid then post
		{
		[_center postNotification:notification];
		return YES;
		}
	return NO;
}

- (void) enqueueNotification:(NSNotification*)notification
				postingStyle:(NSPostingStyle)postingStyle	
{
	[self enqueueNotification:notification
		  postingStyle:postingStyle
		  coalesceMask:NSNotificationCoalescingOnName 
						+ NSNotificationCoalescingOnSender 
		  forModes:nil];
}

- (void) enqueueNotification:(NSNotification*)notification
				postingStyle:(NSPostingStyle)postingStyle
				coalesceMask:(unsigned int)coalesceMask
				forModes:(NSArray*)modes
{
    if (coalesceMask != NSNotificationNoCoalescing)
		[self dequeueNotificationsMatching:notification 
			  coalesceMask:coalesceMask];

    switch (postingStyle) 
		{
		case NSPostNow:
			[self postNotification:notification forModes:modes];
			break;
		case NSPostASAP:
			[notification _addToQueue:_asapQueue forModes:modes];
			break;
		case NSPostWhenIdle:
			[notification _addToQueue:_idleQueue forModes:modes];
			break;
		}
}

- (void) _notifyIdle
{ // post next IDLE notification in queue
	if ([self postNotification:_idleQueue->head->notification 
			  forModes:_idleQueue->head->modes])
		GSRemoveFromQueue(_idleQueue, _idleQueue->head);
}

- (void) _notifyASAP
{ // post all ASAP notifications in queue
    while (_asapQueue->head) 
		if ([self postNotification:_asapQueue->head->notification
		      	  forModes:_asapQueue->head->modes])
			GSRemoveFromQueue(_asapQueue, _asapQueue->head);
}

+ (void) _runLoopIdle
{ // trigger the Idle items
	InstanceList *item;
#if 0
	NSLog(@"_runLoopIdle");
#endif
    for (item = __notificationQueues; item; item = item->next)
		if(((NSNotificationQueue_t *)item->queue)->_idleQueue->head)
			[item->queue _notifyIdle];
}

#if OLD
+ (BOOL) _runLoopMore
{
	InstanceList *item;
    for (item = __notificationQueues; item; item = item->next)
		if(((NSNotificationQueue_t *)item->queue)->_idleQueue->head)
			return YES;
	return NO;
}
#endif

+ (void) _runLoopASAP
{ // trigger the ASAP items
	InstanceList *item;   
#if 0
	NSLog(@"_runLoopASAP");
#endif
    for (item = __notificationQueues; item; item = item->next)
		if(((NSNotificationQueue_t *)item->queue)->_asapQueue->head)
			[item->queue _notifyASAP];
}

@end
