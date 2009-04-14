//
//  NSTrackingArea.h
//  AppKit
//
//  Created by Fabian Spillner on 13.12.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>


@class NSDictionary; 

typedef NSUInteger NSTrackingAreaOptions; 

enum
{
	NSTrackingMouseEnteredAndExited, 
	NSTrackingMouseMoved, 
	NSTrackingCursorUpdate, 
	NSTrackingActiveWhenFirstResponder, 
	NSTrackingActiveInKeyWindow, 
	NSTrackingActiveInActiveApp, 
	NSTrackingActiveAlways, 
	NSTrackingAssumeInside, 
	NSTrackingInVisibleRect, 
	NSTrackingEnabledDuringMouseDrag
};

@interface NSTrackingArea : NSObject 
{
	NSRect _rect;
	NSTrackingAreaOptions _options;
	id _owner;
	NSDictionary *_userInfo;
}

- (NSTrackingArea *) initWithRect:(NSRect) rect 
						  options:(NSTrackingAreaOptions) opts 
							owner:(id) obj 
						 userInfo:(NSDictionary *) info; 
- (NSTrackingAreaOptions) options; 
- (id) owner; 
- (NSRect) rect; 
- (NSDictionary *) userInfo; 

@end
