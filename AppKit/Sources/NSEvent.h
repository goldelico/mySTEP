/* 
   NSEvent.h

   The event class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jun 2006 - aligned with 10.4
   
   Author:	Fabian Spillner
   Date:	23. October 2007

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSEvent
#define _mySTEP_H_NSEvent

#import <Foundation/NSCoder.h>
#import <Foundation/NSGeometry.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSObjCRuntime.h>

@class NSString;
@class NSWindow;
@class NSGraphicsContext;
@class NSTrackingArea; 


typedef enum _NSEventType
{
	NSLeftMouseDown				= 1,
	NSLeftMouseUp				= 2,
	NSRightMouseDown			= 3,
	NSRightMouseUp				= 4,
	NSMouseMoved				= 5,
	NSLeftMouseDragged			= 6,
	NSRightMouseDragged			= 7,
	NSMouseEntered				= 8,
	NSMouseExited				= 9,
	NSKeyDown					= 10,
	NSKeyUp						= 11,
	NSFlagsChanged				= 12,
	NSAppKitDefined				= 13,
	NSSystemDefined				= 14,
	NSApplicationDefined		= 15,
	NSPeriodic					= 16,
	NSCursorUpdate				= 17,
	NSScrollWheel				= 22,
	NSTabletPoint				= 23,
	NSTabletProximity			= 24,	
	NSOtherMouseDown			= 25,
	NSOtherMouseUp				= 26,
	NSOtherMouseDragged			= 27,
// new gesture events as described by http://cocoadex.com/2008/02/nsevent-modifications-swipe-ro.html
	NSRotate					= 18,
	NSBeginGesture				= 19,
	NSEndGesture				= 20,
	NSMagnify					= 30,
	NSSwipe						= 31
} NSEventType;

enum
{
	NSLeftMouseDownMask			= 1<<NSLeftMouseDown,		// t m
	NSLeftMouseUpMask			= 1<<NSLeftMouseUp,			// t m
	NSRightMouseDownMask		= 1<<NSRightMouseDown,		// m
	NSRightMouseUpMask			= 1<<NSRightMouseUp,		// m
	NSMouseMovedMask			= 1<<NSMouseMoved,			// t m
	NSLeftMouseDraggedMask		= 1<<NSLeftMouseDragged,	// t m
	NSRightMouseDraggedMask		= 1<<NSRightMouseDragged,	// m
	NSMouseEnteredMask			= 1<<NSMouseEntered,
	NSMouseExitedMask			= 1<<NSMouseExited,
	NSKeyDownMask				= 1<<NSKeyDown,
	NSKeyUpMask					= 1<<NSKeyUp,
	NSFlagsChangedMask			= 1<<NSFlagsChanged,		// o
	NSAppKitDefinedMask			= 1<<NSAppKitDefined,		// o
	NSSystemDefinedMask			= 1<<NSSystemDefined,		// o
	NSApplicationDefinedMask	= 1<<NSApplicationDefined,	// o
	NSPeriodicMask				= 1<<NSPeriodic,			// t o
	NSCursorUpdateMask			= 1<<NSCursorUpdate,
	NSScrollWheelMask			= 1<<NSScrollWheel,			// m
	NSTabletPointMask			= 1<<NSTabletPoint,
	NSTabletProximityMask		= 1<<NSTabletProximity,
	NSOtherMouseDownMask		= 1<<NSOtherMouseDown,
	NSOtherMouseUpMask			= 1<<NSOtherMouseUp,
	NSOtherMouseDraggedMask		= 1<<NSOtherMouseDragged,
// new gesture events as described by http://cocoadex.com/2008/02/nsevent-modifications-swipe-ro.html
	NSRotateMask				= 1<<NSRotate,
	NSBeginGestureMask			= 1<<NSBeginGesture,
	NSEndGestureMask			= 1<<NSEndGesture,
	NSMagnifyMask				= 1<<NSMagnify,
	NSSwipeMask					= 1<<NSSwipe,
	
	NSAnyEventMask 				= 0xffffffffU,
	
	// private extensions
	
	GSTrackingLoopMask			= (NSLeftMouseDownMask|NSLeftMouseUpMask|NSMouseMovedMask|NSLeftMouseDraggedMask|NSPeriodicMask),		// tracking loops, t's above 
	GSMouseEventMask			= (NSLeftMouseDownMask|NSLeftMouseUpMask|NSRightMouseDownMask|NSRightMouseUpMask|NSMouseMovedMask|
								   NSLeftMouseDraggedMask|NSRightMouseDraggedMask|NSOtherMouseDownMask|NSOtherMouseUpMask|NSOtherMouseDraggedMask|NSScrollWheelMask),	// mouse events, m's above 
	GSOtherEventMask			= (NSFlagsChangedMask|NSAppKitDefinedMask|NSSystemDefinedMask|NSApplicationDefinedMask|NSPeriodicMask)	// other events, o's above 
};

enum
{
	NSAlphaShiftKeyMask = 1*65536,
	NSShiftKeyMask		= 2*65536,
	NSControlKeyMask	= 4*65536,
	NSAlternateKeyMask	= 8*65536,
	NSCommandKeyMask	= 16*65536,
	NSNumericPadKeyMask = 32*65536,
	NSHelpKeyMask		= 64*65536,
	NSFunctionKeyMask	= 128*65536,
	NSDeviceIndependentModifierFlagsMask = 0xffff0000U
};

typedef enum
{
	NSUnknownPointingDevice=-1,
	NSPenPointingDevice,
	NSCursorPointingDevice,
	NSEraserPointingDevice
} NSPointingDeviceType;


enum
{
	NSMouseEventSubtype,
	NSTabletPointEventSubtype,
	NSTabletProximityEventSubtype
};

enum
{
	NSPenTipMask,
	NSPenLowerSideMask,
	NSPenUpperSideMask
};

// NSAppKit Event types

enum
{
	NSWindowExposedEventType			= 0,
	NSApplicationActivatedEventType		= 1,
	NSApplicationDeactivatedEventType	= 2,
	NSWindowMovedEventType				= 4,
	NSScreenChangedEventType			= 8,
	NSAWTEventType						= 16
};

// NSSystemDefined Event types

enum
{
	NSPowerOffEventType	= 1
};

@interface NSEvent : NSObject  <NSCoding, NSCopying>
{
	NSEventType event_type;
	NSPoint location_point;
	unsigned int modifier_flags;
	NSTimeInterval event_time;
	int _windowNum;
	NSGraphicsContext *event_context;
	union _MB_event_data
		{
		struct
			{
			int event_num;
			int click;
			float pressure;
			} mouse;
		struct
			{
			BOOL repeat;
			NSString *char_keys;
			NSString *unmodified_keys;
			unsigned short key_code;
			} key;
		struct
			{
			int event_num;
			int tracking_num;
			void *user_data;
			} tracking;
		struct
			{
			short sub_type;
			int data1;
			int data2;
			} misc;
		} event_data;
}

+ (NSEvent *) enterExitEventWithType:(NSEventType) type	
							location:(NSPoint) location
					   modifierFlags:(NSUInteger) flags
						   timestamp:(NSTimeInterval) time
						windowNumber:(NSInteger) windowNum
							 context:(NSGraphicsContext *) context	
						 eventNumber:(NSInteger) eventNum
					  trackingNumber:(NSInteger) trackingNum
							userData:(void *) userData; 

// + (NSEvent *) eventWithCGEvent:(CGEventRef) ref;
+ (NSEvent *) eventWithEventRef:(const void *) ref;

+ (NSEvent *) keyEventWithType:(NSEventType) type
					  location:(NSPoint) location
				 modifierFlags:(NSUInteger) flags
					 timestamp:(NSTimeInterval) time
				  windowNumber:(NSInteger) windowNum
					   context:(NSGraphicsContext *) context	
					characters:(NSString *) keys	
   charactersIgnoringModifiers:(NSString *) ukeys
					 isARepeat:(BOOL) repeatKey	
					   keyCode:(unsigned short) code;

+ (NSEvent *) mouseEventWithType:(NSEventType) type	
						location:(NSPoint) location
				   modifierFlags:(NSUInteger) flags
					   timestamp:(NSTimeInterval) time
					windowNumber:(NSInteger) windowNum	
					     context:(NSGraphicsContext *) context	
					 eventNumber:(NSInteger) eventNum	
					  clickCount:(NSInteger) clickNum	
					    pressure:(float) pressureValue;

+ (NSPoint) mouseLocation;

+ (NSEvent *) otherEventWithType:(NSEventType) type	
					    location:(NSPoint) location
				   modifierFlags:(NSUInteger) flags
					   timestamp:(NSTimeInterval) time
					windowNumber:(NSInteger) windowNum	
					     context:(NSGraphicsContext *) context	
					     subtype:(short) subType	
					       data1:(NSInteger) data1	
					       data2:(NSInteger) data2;

+ (void) startPeriodicEventsAfterDelay:(NSTimeInterval) delaySeconds
							withPeriod:(NSTimeInterval) periodSeconds;

+ (void) stopPeriodicEvents;							// Periodic Events

- (NSInteger) absoluteX;
- (NSInteger) absoluteY;
- (NSInteger) absoluteZ;
- (NSUInteger) buttonMask;
- (NSInteger) buttonNumber;
- (NSUInteger) capabilityMask;
- (NSString *) characters;								// Key Event Info
- (NSString *) charactersIgnoringModifiers;
- (NSInteger) clickCount;										// Mouse Event Info
- (NSGraphicsContext *) context;								// Event Information
- (NSInteger) data1;											// Special Events
- (NSInteger) data2;
- (CGFloat) deltaX;
- (CGFloat) deltaY;
- (CGFloat) deltaZ;
- (NSUInteger) deviceID;
- (NSInteger) eventNumber;
- (const void *) eventRef;
- (BOOL) isARepeat;
- (BOOL) isEnteringProximity;
- (BOOL) isGesture;				// new gesture events as described by http://cocoadex.com/2008/02/nsevent-modifications-swipe-ro.html
- (unsigned short) keyCode;
- (NSPoint) locationInWindow;
- (float) magnification;		// new gesture events as described by http://cocoadex.com/2008/02/nsevent-modifications-swipe-ro.html
- (NSUInteger) modifierFlags;
- (NSUInteger) pointingDeviceID;
- (NSUInteger) pointingDeviceSerialNumber;
- (NSPointingDeviceType) pointingDeviceType;
- (float) pressure;
- (float) rotation;
- (float) standardMagnificationThreshold;	// new gesture events as described by http://cocoadex.com/2008/02/nsevent-modifications-swipe-ro.html
- (float) standardRotationThreshold;		// new gesture events as described by http://cocoadex.com/2008/02/nsevent-modifications-swipe-ro.html
- (short) subtype;
- (NSUInteger) systemTabletID;
- (NSUInteger) tabletID;
- (float) tangentialPressure;
- (NSPoint) tilt;
- (NSTimeInterval) timestamp;
- (NSTrackingArea *) trackingArea;
- (NSInteger) trackingNumber;									// Tracking Event Info
- (NSEventType) type;
- (unsigned long long) uniqueID;
- (void *) userData;
- (id) vendorDefined;
- (NSUInteger) vendorID;
- (NSUInteger) vendorPointingDeviceType;
- (NSWindow *) window;
- (NSInteger) windowNumber;

@end

enum {
    NSBackspaceKey		= 8,
    NSCarriageReturnKey	= 13,
    NSDeleteKey			= 0x7f,
    NSBacktabKey		= 25
};

enum {
	NSUpArrowFunctionKey = 0xF700,
	NSDownArrowFunctionKey = 0xF701,
	NSLeftArrowFunctionKey = 0xF702,
	NSRightArrowFunctionKey = 0xF703,
	NSF1FunctionKey  = 0xF704,
	NSF2FunctionKey  = 0xF705,
	NSF3FunctionKey  = 0xF706,
	NSF4FunctionKey  = 0xF707,
	NSF5FunctionKey  = 0xF708,
	NSF6FunctionKey  = 0xF709,
	NSF7FunctionKey  = 0xF70A,
	NSF8FunctionKey  = 0xF70B,
	NSF9FunctionKey  = 0xF70C,
	NSF10FunctionKey = 0xF70D,
	NSF11FunctionKey = 0xF70E,
	NSF12FunctionKey = 0xF70F,
	NSF13FunctionKey = 0xF710,
	NSF14FunctionKey = 0xF711,
	NSF15FunctionKey = 0xF712,
	NSF16FunctionKey = 0xF713,
	NSF17FunctionKey = 0xF714,
	NSF18FunctionKey = 0xF715,
	NSF19FunctionKey = 0xF716,
	NSF20FunctionKey = 0xF717,
	NSF21FunctionKey = 0xF718,
	NSF22FunctionKey = 0xF719,
	NSF23FunctionKey = 0xF71A,
	NSF24FunctionKey = 0xF71B,
	NSF25FunctionKey = 0xF71C,
	NSF26FunctionKey = 0xF71D,
	NSF27FunctionKey = 0xF71E,
	NSF28FunctionKey = 0xF71F,
	NSF29FunctionKey = 0xF720,
	NSF30FunctionKey = 0xF721,
	NSF31FunctionKey = 0xF722,
	NSF32FunctionKey = 0xF723,
	NSF33FunctionKey = 0xF724,
	NSF34FunctionKey = 0xF725,
	NSF35FunctionKey = 0xF726,
	NSInsertFunctionKey = 0xF727,
	NSDeleteFunctionKey = 0xF728,
	NSHomeFunctionKey = 0xF729,
	NSBeginFunctionKey = 0xF72A,
	NSEndFunctionKey = 0xF72B,
	NSPageUpFunctionKey = 0xF72C,
	NSPageDownFunctionKey = 0xF72D,
	NSPrintScreenFunctionKey = 0xF72E,
	NSScrollLockFunctionKey = 0xF72F,
	NSPauseFunctionKey = 0xF730,
	NSSysReqFunctionKey = 0xF731,
	NSBreakFunctionKey = 0xF732,
	NSResetFunctionKey = 0xF733,
	NSStopFunctionKey = 0xF734,
	NSMenuFunctionKey = 0xF735,
	NSUserFunctionKey = 0xF736,
	NSSystemFunctionKey = 0xF737,
	NSPrintFunctionKey = 0xF738,
	NSClearLineFunctionKey = 0xF739,
	NSClearDisplayFunctionKey = 0xF73A,
	NSInsertLineFunctionKey = 0xF73B,
	NSDeleteLineFunctionKey = 0xF73C,
	NSInsertCharFunctionKey = 0xF73D,
	NSDeleteCharFunctionKey = 0xF73E,
	NSPrevFunctionKey = 0xF73F,
	NSNextFunctionKey = 0xF740,
	NSSelectFunctionKey = 0xF741,
	NSExecuteFunctionKey = 0xF742,
	NSUndoFunctionKey = 0xF743,
	NSRedoFunctionKey = 0xF744,
	NSFindFunctionKey = 0xF745,
	NSHelpFunctionKey = 0xF746,
	NSModeSwitchFunctionKey = 0xF747
};

// Event mask to event type

extern unsigned int NSEventMaskFromType(NSEventType type);

#endif /* _mySTEP_H_NSEvent */
