/* 
   NSEvent.m

   Object representation of application events

   Copyright (C) 1996 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSDictionary.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSException.h>

#import <AppKit/NSEvent.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSMenu.h>

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"

// Class variables
static NSString	*__timers = @"NSEventTimersKey";


@implementation NSEvent

+ (NSEvent *) enterExitEventWithType:(NSEventType)t	
							location:(NSPoint)location
							modifierFlags:(unsigned int)flags
							timestamp:(NSTimeInterval)time
							windowNumber:(int)windowNum
							context:(NSGraphicsContext *)context	
							eventNumber:(int)eventNum
							trackingNumber:(int)trackingNum
							userData:(void *)userData
{
NSEvent *e = [[NSEvent new] autorelease];

	if(t != NSMouseEntered && t != NSMouseExited && t != NSCursorUpdate)
		[NSException raise:NSInvalidArgumentException 
					 format:@"Not an enter or exit event"];

	e->event_type = t;
	e->location_point = location;
	e->modifier_flags = flags;
	e->event_time = time;
	e->_windowNum = windowNum;
	e->event_context = context;
	e->event_data.tracking.event_num = eventNum;
	e->event_data.tracking.tracking_num = trackingNum;
	e->event_data.tracking.user_data = userData;

	return e;
}

+ (NSEvent *) keyEventWithType:(NSEventType)type
					  location:(NSPoint)location
					  modifierFlags:(unsigned int)flags
					  timestamp:(NSTimeInterval)time
					  windowNumber:(int)windowNum
					  context:(NSGraphicsContext *)context	
					  characters:(NSString *)keys	
					  charactersIgnoringModifiers:(NSString *)ukeys
					  isARepeat:(BOOL)repeatKey	
					  keyCode:(unsigned short)code
{
NSEvent *e = [[NSEvent new] autorelease];

	switch(type)
		{
		case NSKeyDown:
		case NSKeyUp:
		case NSFlagsChanged:
			break;
		default:
			[NSException raise:NSInvalidArgumentException 
					 format:@"Not a key event (%d)", type];
		}
	e->event_type = type;
	e->location_point = location;
	e->modifier_flags = flags;
	e->event_time = time;
	e->_windowNum = windowNum;
	e->event_context = context;
	e->event_data.key.char_keys = [keys retain];
	e->event_data.key.unmodified_keys = [ukeys retain];
	e->event_data.key.repeat = repeatKey;
	e->event_data.key.key_code = code;

	return e;
}

+ (NSEvent *) mouseEventWithType:(NSEventType)t	
						location:(NSPoint)location
						modifierFlags:(unsigned int)flags
						timestamp:(NSTimeInterval)time
						windowNumber:(int)windowNum 
						context:(NSGraphicsContext *)context 
						eventNumber:(int)eventNum	
						clickCount:(int)clickNum	
						pressure:(float)pressureValue
{
	NSEvent *e = [[NSEvent new] autorelease];

	if (!(NSEventMaskFromType(t) & GSMouseEventMask))
		[NSException raise:NSInvalidArgumentException 
					 format:@"Not a mouse event"];

	e->event_type = t;
	e->location_point = location;
	e->modifier_flags = flags;
	e->event_time = time;
	e->_windowNum = windowNum;
	e->event_context = context;
	e->event_data.mouse.event_num = eventNum;
	e->event_data.mouse.click = clickNum;
	e->event_data.mouse.pressure = pressureValue;

	return e;
}

+ (NSEvent *) otherEventWithType:(NSEventType)t	
						location:(NSPoint)location
						modifierFlags:(unsigned int)flags
						timestamp:(NSTimeInterval)time
						windowNumber:(int)windowNum 
						context:(NSGraphicsContext *)context 
						subtype:(short)subType	
						data1:(int)data1	
						data2:(int)data2
{
	NSEvent *e = [[NSEvent new] autorelease];

	if (!(NSEventMaskFromType(t) & GSOtherEventMask))
		[NSException raise:NSInvalidArgumentException 
					 format:@"Not an event of type other"];
	
	e->event_type = t;
	e->location_point = location;
	e->modifier_flags = flags;
	e->event_time = time;
	e->_windowNum = windowNum;
	e->event_context = context;
	e->event_data.misc.sub_type = subType;
	e->event_data.misc.data1 = data1;
	e->event_data.misc.data2 = data2;

	return e;
}
															
+ (void) startPeriodicEventsAfterDelay:(NSTimeInterval)delaySeconds
							withPeriod:(NSTimeInterval)periodSeconds
{
	NSMutableDictionary *d = [[NSThread currentThread] threadDictionary];
	NSTimer *t;
#if 1
	NSLog (@"startPeriodicEventsAfterDelay:%lf withPeriod:%lf", delaySeconds, periodSeconds);
#endif 
	if ([d objectForKey: __timers])						// Check this thread for a pending timer
		[NSException raise:NSInternalInconsistencyException
					 format:@"Periodic events are already being generated for thread %@ by timer %@", [NSThread currentThread], [d objectForKey: __timers]];

							// If delay time is 0 register timer immediately.
	if (!delaySeconds)		// Otherwise register a one shot timer to do it.
		t = [NSTimer timerWithTimeInterval:periodSeconds	// register an
					 target:self							// immediate
					 selector:@selector(_timerFired:)		// timer
					 userInfo:nil
					 repeats:YES];
	else													// register a one
		t = [NSTimer timerWithTimeInterval:delaySeconds 	// shot timer to 
					 target:self							// register a timer 
					 selector:@selector(_registerRealTimer:)
					 userInfo:[NSNumber numberWithDouble:periodSeconds]
					 repeats:NO];

	[[NSRunLoop currentRunLoop] addTimer:t forMode:NSEventTrackingRunLoopMode];
	[d setObject:t forKey:__timers];
}

+ (void) _timerFired:(NSTimer *)timer
{
NSEvent *e = [self otherEventWithType:NSPeriodic
				   location:NSZeroPoint
				   modifierFlags:0
				   timestamp:[[NSDate date] timeIntervalSinceReferenceDate]
				   windowNumber:0
				   context:[NSApp context]
				   subtype:0
				   data1:0
				   data2:0];
#if 1
	NSLog (@"periodic _timerFired:");
#endif
	[NSApp postEvent:e atStart:NO];				// queue up the periodic event
}

+ (void) _registerRealTimer:(NSTimer *)timer		// provides a way to delay the
{												// start of periodic events
NSTimer *t = [NSTimer timerWithTimeInterval:[[timer userInfo] doubleValue]
					  target:self
					  selector:@selector(_timerFired:)
					  userInfo:nil
					  repeats:YES];

	NSDebugLog (@"_registerRealTimer:");		// Add real timer to the timers
												// dictionary and to run loop
	[[[NSThread currentThread] threadDictionary] setObject:t forKey:__timers];		
	[[NSRunLoop currentRunLoop] addTimer:t forMode:NSEventTrackingRunLoopMode];
}

+ (void) stopPeriodicEvents
{
	NSMutableDictionary *d = [[NSThread currentThread] threadDictionary];
#if 1
	NSLog (@"stopPeriodicEvents");
#endif
	[[d objectForKey: __timers] invalidate];	// Remove any existing timer
	[d removeObjectForKey: __timers];			// for this thread
}

+ (NSPoint) mouseLocation
{ // ask main window (if present)
	NSWindow *win=[NSApp keyWindow];	// try key window
	if(!win)
		win=[NSApp mainWindow];			// try main window
	if(!win)
		win=[NSApp _mainMenuWindow];	// try main menu window
	if(!win)
		win=[[NSApp windows] lastObject];	// try any other window
	if(!win)
		{
		NSLog(@"mouseLocation: there is no key/main/mainMenu window");
		return NSZeroPoint;
		}
	return [[win screen] _mouseLocation];	// query mouse location on screen
}

- (id) copyWithZone:(NSZone *) zone;
{
	return [self retain];	// no need to really copy - we are not mutable!
}

- (void) dealloc
{
	if ((event_type == NSKeyUp) || (event_type == NSKeyDown))
		{
		[event_data.key.char_keys release];
		[event_data.key.unmodified_keys release];
		}

	[super dealloc];
}

- (NSGraphicsContext *) context			{ return event_context; }
- (NSPoint) locationInWindow	{ return location_point; }
- (unsigned int) modifierFlags	{ return modifier_flags; }
- (NSTimeInterval) timestamp	{ return event_time; }
- (NSEventType) type			{ return event_type; }
- (int) windowNumber			{ return _windowNum; }

- (NSWindow *) window
{
	return [NSApp windowWithWindowNumber:_windowNum];
}

- (NSString *) characters								// Key Event Info
{
	if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
		return nil;
	return event_data.key.char_keys;
}

- (NSString *) charactersIgnoringModifiers
{
	if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
		return nil;
	return event_data.key.unmodified_keys;
}

- (BOOL) isARepeat
{
	if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
		return NO;
	return event_data.key.repeat;
}

- (unsigned short) keyCode
{
	if ((event_type != NSKeyUp) && (event_type != NSKeyDown))
		return 0;
	return event_data.key.key_code;
}

- (int) clickCount										// Mouse Event Info
{
	if (!(NSEventMaskFromType(event_type) & GSMouseEventMask))
		return 0;										// must be mouse event
	return event_data.mouse.click;
}

- (int) eventNumber
{
	if ((event_type == NSMouseEntered) || (event_type == NSMouseExited) || (event_type == NSCursorUpdate))
		return event_data.tracking.event_num;
	if (!(NSEventMaskFromType(event_type) & GSMouseEventMask))
		return 0;
	return event_data.mouse.event_num;
}

- (float) deltaX
{
	if (!(NSEventMaskFromType(event_type) & GSMouseEventMask))
		return 0;
	return event_data.mouse.pressure;	// FIXME: ????
}

- (float) pressure
{
	if (!(NSEventMaskFromType(event_type) & GSMouseEventMask))
		[NSException raise:NSInternalInconsistencyException format:@"pressure not defined"];
	return event_data.mouse.pressure;
}

- (int) trackingNumber									// Tracking Event Info
{
	if ((event_type != NSMouseEntered) && (event_type != NSMouseExited) && (event_type != NSCursorUpdate))
		[NSException raise:NSInternalInconsistencyException format:@"trackingNumber not defined for %@", self];
	return event_data.tracking.tracking_num;
}

- (void *) userData
{
	if ((event_type != NSMouseEntered) && (event_type != NSMouseExited) && (event_type != NSCursorUpdate))
		[NSException raise:NSInternalInconsistencyException format:@"userData not defined for %@", self];
	return event_data.tracking.user_data;
}

- (int) data1											// Special Events info
{
	switch(event_type)
		{
		case NSAppKitDefined:
		case NSSystemDefined:
		case NSApplicationDefined:
		case NSPeriodic:
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"data1 not defined"];
		}
	return event_data.misc.data1;
}

- (int) data2
{
	switch(event_type)
		{
		case NSAppKitDefined:
		case NSSystemDefined:
		case NSApplicationDefined:
		case NSPeriodic:
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"data2 not defined"];
		}
	return event_data.misc.data2;
}

- (short) subtype
{
	switch(event_type)
		{
		case NSAppKitDefined:
		case NSSystemDefined:
		case NSApplicationDefined:
		case NSPeriodic:
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"subtype not defined"];
		}
	return event_data.misc.sub_type;
}

- (void) encodeWithCoder:(NSCoder *) aCoder							// NSCoding protocol
{
	[aCoder encodeValueOfObjCType: @encode(NSEventType) at: &event_type];
	[aCoder encodePoint: location_point];
	[aCoder encodeValueOfObjCType: "I" at: &modifier_flags];
	[aCoder encodeValueOfObjCType: @encode(NSTimeInterval) at: &event_time];
	[aCoder encodeValueOfObjCType: "i" at: &_windowNum];
	
	switch (event_type)							// Encode the event date based 
		{										// upon the event type
		case NSLeftMouseDown:
		case NSLeftMouseUp:
		case NSRightMouseDown:
		case NSRightMouseUp:
		case NSMouseMoved:
		case NSLeftMouseDragged:
		case NSRightMouseDragged:
		case NSOtherMouseDown:
		case NSOtherMouseUp:
		case NSOtherMouseDragged:
		case NSScrollWheel:
			[aCoder encodeValuesOfObjCTypes: "iif", 
					&event_data.mouse.event_num, &event_data.mouse.click, 
					&event_data.mouse.pressure];
			break;
		
		case NSMouseEntered:
		case NSMouseExited:
		case NSCursorUpdate:		// Can't do anything with the user_data!?
			[aCoder encodeValuesOfObjCTypes: "ii", 
					&event_data.tracking.event_num, 
					&event_data.tracking.tracking_num];
			break;
		
		case NSKeyDown:
		case NSKeyUp:
			[aCoder encodeValueOfObjCType: @encode(BOOL) at: 
					&event_data.key.repeat];
			[aCoder encodeObject: event_data.key.char_keys];
			[aCoder encodeObject: event_data.key.unmodified_keys];
			[aCoder encodeValueOfObjCType: "S" at: &event_data.key.key_code];
			break;
		
		case NSFlagsChanged:
		case NSPeriodic:
		case NSAppKitDefined:
		case NSSystemDefined:
		case NSApplicationDefined:
			[aCoder encodeValuesOfObjCTypes: "sii", &event_data.misc.sub_type,
					&event_data.misc.data1, &event_data.misc.data2];
			break;
		case NSTabletPoint:
		case NSTabletProximity:
			NIMP;
			break;
			case NSRotate:
			case NSBeginGesture:
			case NSEndGesture:
			case NSMagnify:
			case NSSwipe:				
				NIMP;
				break;
		}
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	if([aDecoder allowsKeyedCoding])
		return self;
	[aDecoder decodeValueOfObjCType: @encode(NSEventType) at: &event_type];
	location_point = [aDecoder decodePoint];
	[aDecoder decodeValueOfObjCType: "I" at: &modifier_flags];
	[aDecoder decodeValueOfObjCType: @encode(NSTimeInterval) at: &event_time];
	[aDecoder decodeValueOfObjCType: "i" at: &_windowNum];

	switch (event_type)							// Decode the event date based 
		{										// upon the event type
		case NSLeftMouseDown:
		case NSLeftMouseUp:
		case NSRightMouseDown:
		case NSRightMouseUp:
		case NSMouseMoved:
		case NSLeftMouseDragged:
		case NSRightMouseDragged:
		case NSOtherMouseDown:
		case NSOtherMouseUp:
		case NSOtherMouseDragged:
		case NSScrollWheel:
			[aDecoder decodeValuesOfObjCTypes:"iif", 
							&event_data.mouse.event_num, 
							&event_data.mouse.click, 
							&event_data.mouse.pressure];
			break;
	
		case NSMouseEntered:
		case NSMouseExited:
		case NSCursorUpdate:		// Can't do anything with the user_data!?
			[aDecoder decodeValuesOfObjCTypes: "ii", 
							&event_data.tracking.event_num, 
							&event_data.tracking.tracking_num];
			break;
	
		case NSKeyDown:
		case NSKeyUp:
			[aDecoder decodeValueOfObjCType: @encode(BOOL) 
					  at: &event_data.key.repeat];
			event_data.key.char_keys = [aDecoder decodeObject];
			event_data.key.unmodified_keys = [aDecoder decodeObject];
			[aDecoder decodeValueOfObjCType: "S" at: &event_data.key.key_code];
			break;
	
		case NSFlagsChanged:
		case NSPeriodic:
		case NSAppKitDefined:
		case NSSystemDefined:
		case NSApplicationDefined:
			[aDecoder decodeValuesOfObjCTypes:"sii", &event_data.misc.sub_type, 
													 &event_data.misc.data1, 
													 &event_data.misc.data2];
			break;
		case NSTabletPoint:
		case NSTabletProximity:
			NIMP;
			break;
			case NSRotate:
			case NSBeginGesture:
			case NSEndGesture:
			case NSMagnify:
			case NSSwipe:				
				NIMP;
				break;
		}

	return self;
}

- (NSString *) _modifier_flags
{
	NSMutableString *str=[NSMutableString string];
	if(modifier_flags&NSAlphaShiftKeyMask)
		[str appendString:@" ash"];
	if(modifier_flags&NSShiftKeyMask)
		[str appendString:@" sh"];
	if(modifier_flags&NSControlKeyMask)
		[str appendString:@" ctl"];
	if(modifier_flags&NSAlternateKeyMask)
		[str appendString:@" alt"];
	if(modifier_flags&NSCommandKeyMask)
		[str appendString:@" cmd"];
	if(modifier_flags&NSNumericPadKeyMask)
		[str appendString:@" num"];
	if(modifier_flags&NSHelpKeyMask)
		[str appendString:@" help"];
	if(modifier_flags&NSFunctionKeyMask)
		[str appendString:@" fn"];
	return str;
}

- (NSString *) description
{	
	const char *types[] = {
		"NSLeftMouseDown",	// 1
		"NSLeftMouseUp",
		"NSRightMouseDown",
		"NSRightMouseUp",
		"NSMouseMoved",
		"NSLeftMouseDragged",
		"NSRightMouseDragged",
		"NSMouseEntered",
		"NSMouseExited",
		"NSKeyDown",
		"NSKeyUp",
		"NSFlagsChanged",
		"NSAppKitDefined",
		"NSSystemDefined",
		"NSApplicationDefined",
		"NSPeriodic",
		"NSCursorUpdate",
		"?18?",
		"?19?",
		"?20?",
		"?21?",
		"NSScrollWheel",
		"NSTabletPoint",
		"NSTabletProximity",
		"NSOtherMouseDown",
		"NSOtherMouseUp",
		"NSOtherMouseDragged",
	};
	if(sizeof(types)/sizeof(types[0]) != NSOtherMouseDragged) // should be optimized away by compiler as dead code if both constants are the same
		NSLog(@"NSOtherMouseDragged=%d sizeof(types)=%d", NSOtherMouseDragged, sizeof(types)/sizeof(types[0]));
	switch (event_type) 
		{
		case NSLeftMouseDown:
		case NSLeftMouseUp:
		case NSRightMouseDown:
		case NSRightMouseUp:
		case NSOtherMouseDown:
		case NSOtherMouseUp:
		case NSLeftMouseDragged:
		case NSRightMouseDragged:
		case NSOtherMouseDragged:
		case NSMouseMoved:
		case NSScrollWheel:
			return [NSString stringWithFormat:
				@"NSEvent: eventType = %s, point = { %f, %f }, modifiers =%@,"
				@" time = %f, window = %d, Context = %p,"
				@" event number = %d, click = %d, pressure = %f",
				types[event_type - 1], location_point.x, location_point.y,
				[self _modifier_flags], event_time, _windowNum, event_context,
				event_data.mouse.event_num, event_data.mouse.click,
				event_data.mouse.pressure];
	
		case NSMouseEntered:
		case NSMouseExited:
			return [NSString stringWithFormat:
				@"NSEvent: eventType = %s, point = { %f, %f }, modifiers =%@,"
				@" time = %f, window = %d, Context = %p, "
				@" event number = %d, tracking number = %d, user data = %p",
				types[event_type - 1], location_point.x, location_point.y,
				[self _modifier_flags], event_time, _windowNum, event_context,
				event_data.tracking.event_num,
				event_data.tracking.tracking_num,
				event_data.tracking.user_data];
	
		case NSKeyDown:
		case NSKeyUp:
		case NSFlagsChanged:
			return [NSString stringWithFormat:
				@"NSEvent: eventType = %s, point = { %f, %f }, modifiers =%@,"
				@" time = %f, window = %d, Context = %p, "
				@" repeat = %s, keys = %@, ukeys = %@, keyCode = 0x%x",
				types[event_type - 1], location_point.x, location_point.y,
				[self _modifier_flags], event_time, _windowNum, event_context,
				(event_data.key.repeat ? "YES" : "NO"),
				event_data.key.char_keys, event_data.key.unmodified_keys,
				event_data.key.key_code];
	
		case NSPeriodic:
		case NSCursorUpdate:
		case NSAppKitDefined:
		case NSSystemDefined:
		case NSApplicationDefined:
			return [NSString stringWithFormat:
				@"NSEvent: eventType = %s, point = { %f, %f }, modifiers =%@,"
				@" time = %f, window = %d, Context = %p, "
				@" subtype = %d, data1 = %p, data2 = %p",
				types[event_type - 1], location_point.x, location_point.y,
				[self _modifier_flags], event_time, _windowNum, event_context,
				event_data.misc.sub_type, event_data.misc.data1,
				event_data.misc.data2];
		case NSTabletPoint:
		case NSTabletProximity:
			// NIMP;
			break;			
			case NSRotate:
			case NSBeginGesture:
			case NSEndGesture:
			case NSMagnify:
			case NSSwipe:				
//				NIMP;
				break;
		}

	return [NSString stringWithFormat:@"NSEvent: unknown event type = %d", event_type];
}

+ (NSEvent *) eventWithCGEvent:(CGEventRef) ref; { return NIMP; }
+ (NSEvent *) eventWithEventRef:(const void *) ref; { return NIMP; }

@end

unsigned int 
NSEventMaskFromType(NSEventType type)			// Convert an NSEvent Type to 
{												// it's respective Event Mask	
	switch(type)										
		{												
		case NSLeftMouseDown:		return NSLeftMouseDownMask;
		case NSLeftMouseUp:			return NSLeftMouseUpMask;
		case NSRightMouseDown:		return NSRightMouseDownMask;
		case NSRightMouseUp:		return NSRightMouseUpMask;
		case NSOtherMouseDown:		return NSOtherMouseDownMask;
		case NSOtherMouseUp:		return NSOtherMouseUpMask;
		case NSMouseMoved:			return NSMouseMovedMask;
		case NSMouseEntered:		return NSMouseEnteredMask;
		case NSMouseExited:			return NSMouseExitedMask;
		case NSLeftMouseDragged:	return NSLeftMouseDraggedMask;
		case NSRightMouseDragged:	return NSRightMouseDraggedMask;
		case NSOtherMouseDragged:	return NSOtherMouseDraggedMask;
		case NSKeyDown:				return NSKeyDownMask;
		case NSKeyUp:				return NSKeyUpMask;
		case NSFlagsChanged:		return NSFlagsChangedMask;
		case NSPeriodic:			return NSPeriodicMask;
		case NSCursorUpdate:		return NSCursorUpdateMask;
		case NSAppKitDefined:		return NSAppKitDefinedMask;
		case NSSystemDefined:		return NSSystemDefinedMask;
		case NSApplicationDefined:	return NSApplicationDefinedMask;
		case NSScrollWheel:			return NSScrollWheelMask;
			case NSRotate:
			case NSBeginGesture:
			case NSEndGesture:
			case NSMagnify:
			case NSSwipe:				
			default:					return 0;
		}
}
